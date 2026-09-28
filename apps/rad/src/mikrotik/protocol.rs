use anyhow::Ok;
use tokio::io::{AsyncRead, AsyncReadExt, AsyncWrite, AsyncWriteExt};

#[derive(Debug)]
pub struct Sentence {
    words: Vec<String>,
}

impl Sentence {
    pub fn new(words: impl IntoIterator<Item = String>) -> Self {
        Self {
            words: words.into_iter().collect(),
        }
    }

    pub(crate) fn words(&self) -> &[String] {
        &self.words
    }
}

pub struct MikrotikStream<T>(T);

impl<T: AsyncWrite + AsyncRead + Unpin> MikrotikStream<T> {
    pub fn new(writer: T) -> Self {
        Self(writer)
    }

    pub async fn write(&mut self, sentence: Sentence) -> anyhow::Result<()> {
        for word in sentence.words {
            self.write_word(word).await?;
        }

        self.write_word(String::new()).await?;

        Ok(())
    }

    async fn write_word(&mut self, word: String) -> anyhow::Result<()> {
        self.write_length(word.len().try_into()?).await?;
        self.0.write_all(word.as_bytes()).await?;

        Ok(())
    }

    // https://manual.mikrotik.com/docs/developer-guides/api/python3-example/
    async fn write_length(&mut self, value: u32) -> anyhow::Result<()> {
        if value < 0x80 {
            self.0.write_u8(value.try_into().unwrap()).await?;
        } else if value < 0x4000 {
            self.0
                .write_u16((value | 0x8000).try_into().unwrap())
                .await?;
        } else if value < 0x200_000 {
            let converted = value | 0xC00_000;

            self.0
                .write_u8(((converted >> 16) & 0xFF).try_into().unwrap())
                .await?;
            self.0
                .write_u8(((converted >> 8) & 0xFF).try_into().unwrap())
                .await?;
            self.0
                .write_u8((converted & 0xFF).try_into().unwrap())
                .await?;
        } else if value < 0x10_000_000 {
            self.0.write_u32(value | 0xE0_000_000).await?;
        } else {
            self.0.write_u8(0xF0).await?;
            self.0.write_u32(value).await?;
        }

        Ok(())
    }

    pub async fn read(&mut self) -> anyhow::Result<Sentence> {
        let mut words = vec![];

        while let word = self.read_word().await?
            && !word.is_empty()
        {
            words.push(word);
        }

        Ok(Sentence { words })
    }

    async fn read_word(&mut self) -> anyhow::Result<String> {
        let length = self.read_length().await?;
        let mut buffer = vec![0u8; length.try_into()?];
        self.0.read_exact(&mut buffer).await?;

        Ok(String::from_utf8(buffer)?)
    }

    async fn read_length(&mut self) -> anyhow::Result<u32> {
        let byte0: u32 = self.0.read_u8().await?.into();

        if (byte0 & 0x80) == 0 {
            Ok(byte0)
        } else if (byte0 & 0xC0) == 0x80 {
            Ok((((byte0 as u32) & !0xC0) << 8) | (self.0.read_u8().await? as u32))
        } else if (byte0 & 0xE0) == 0xC0 {
            Ok((((byte0 as u32) & !0xE0) << 16)
                | ((self.0.read_u8().await? as u32) << 8)
                | (self.0.read_u8().await? as u32))
        } else if (byte0 & 0xF0) == 0xE0 {
            Ok(((byte0 & !0xF0) << 24)
                | ((self.0.read_u8().await? as u32) << 16)
                | ((self.0.read_u8().await? as u32) << 8)
                | (self.0.read_u8().await? as u32))
        } else {
            Ok(self.0.read_u32().await?)
        }
    }
}
