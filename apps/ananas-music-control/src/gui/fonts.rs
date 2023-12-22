use fontdue::Font;

pub struct Fonts {
    fonts: Vec<Font>,
}

#[derive(Debug, Copy, Clone)]
pub enum FontKind {
    MainText,
    Emoji,
}

impl<'a> Fonts {
    pub fn new(main_text_font: Font, emoji_font: Font) -> Self {
        Self {
            fonts: vec![main_text_font, emoji_font],
        }
    }

    pub fn index_of(&self, kind: FontKind) -> usize {
        match kind {
            FontKind::MainText => 0,
            FontKind::Emoji => 1,
        }
    }

    pub fn all(&'a self) -> &'a [Font] {
        &self.fonts
    }
}
