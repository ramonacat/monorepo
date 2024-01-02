use std::fs::File;
use std::io::BufReader;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{channel, Sender};
use std::sync::Arc;
use std::thread::JoinHandle;
use std::time::Duration;
use std::{sync::Mutex, thread};

use cpal::traits::HostTrait;
use rodio::{Decoder, OutputStream, Sink, Source};

use crate::library::Track;

type StatusCallback = Arc<Mutex<Box<dyn Fn(PlaybackStatus) + Send>>>;

struct StatusReportingDecoder<TSource: rodio::Source>
where
    <TSource as Iterator>::Item: rodio::Sample,
{
    inner: TSource,
    samples_played: u64,
    status_callback: Box<dyn Fn(u64, u64) + Send>,
}

impl<TSource: rodio::Source> StatusReportingDecoder<TSource>
where
    <TSource as Iterator>::Item: rodio::Sample,
{
    fn new(inner: TSource, status_callback: Box<dyn Fn(u64, u64) + Send>) -> Self {
        Self {
            inner,
            samples_played: 0,
            status_callback,
        }
    }
}

impl<TSource: rodio::Source> Iterator for StatusReportingDecoder<TSource>
where
    <TSource as Iterator>::Item: rodio::Sample,
{
    type Item = TSource::Item;

    fn next(&mut self) -> Option<Self::Item> {
        self.samples_played += 1;

        let samples_per_second = self.sample_rate() as u64 * self.channels() as u64;
        if self.samples_played % samples_per_second == 0 {
            (self.status_callback)(
                self.samples_played / samples_per_second,
                self.total_duration().unwrap().as_secs(),
            )
        }

        self.inner.next()
    }
}

impl<TSource: rodio::Source> rodio::Source for StatusReportingDecoder<TSource>
where
    <TSource as Iterator>::Item: rodio::Sample,
{
    fn current_frame_len(&self) -> Option<usize> {
        self.inner.current_frame_len()
    }

    fn channels(&self) -> u16 {
        self.inner.channels()
    }

    fn sample_rate(&self) -> u32 {
        self.inner.sample_rate()
    }

    fn total_duration(&self) -> Option<Duration> {
        self.inner.total_duration()
    }
}

enum PlayerCommand {
    Play,
    Pause,
    Stop,
    Exit,
}

pub struct PlaybackStatus {
    progress: u32,
    progress_max: u32,
    title: String,
    album_title: String,
    album_artist: String,
}

impl PlaybackStatus {
    pub fn elapsed(&self) -> u32 {
        self.progress
    }
    pub fn total_length(&self) -> u32 {
        self.progress_max
    }

    pub fn title(&self) -> &str {
        &self.title
    }

    pub fn album_title(&self) -> &str {
        &self.album_title
    }

    pub fn album_artist(&self) -> &str {
        &self.album_artist
    }
}

pub struct Player {
    queue: Arc<Mutex<Vec<Track>>>,
    queue_thread: JoinHandle<()>,
    tx: Sender<PlayerCommand>,
    status_callback: StatusCallback,
    pause_status: Arc<AtomicBool>,
}

impl Player {
    pub fn new() -> Self {
        let queue = Arc::new(Mutex::new(vec![]));
        let queue_ = queue.clone();

        let status_callback: StatusCallback = Arc::new(Mutex::new(Box::new(|_| {})));
        let status_callback_ = status_callback.clone();

        let pause_status = Arc::new(AtomicBool::new(true));
        let pause_status_ = pause_status.clone();

        let (tx, rx) = channel();

        Self {
            queue,
            queue_thread: thread::spawn(move || {
                let cpal_dev = cpal::default_host().default_output_device().unwrap();
                let (stream, stream_handle) = OutputStream::try_from_device(&cpal_dev).unwrap();

                let sink = Arc::new(Sink::try_new(&stream_handle).unwrap());
                let sink_ = sink.clone();

                sink.pause();
                let sink = sink_;
                let queue = queue_;

                let exit = AtomicBool::new(false);

                let handle_command = |command: PlayerCommand| match command {
                    PlayerCommand::Play => {
                        sink.play();
                        pause_status_.store(false, Ordering::SeqCst);
                    }
                    PlayerCommand::Pause => {
                        sink.pause();
                        pause_status_.store(true, Ordering::SeqCst);
                    }
                    PlayerCommand::Stop => {
                        sink.stop();
                        pause_status_.store(true, Ordering::SeqCst);
                    }
                    PlayerCommand::Exit => exit.store(true, Ordering::SeqCst),
                };

                loop {
                    if let Ok(command) = rx.recv_timeout(Duration::from_millis(10)) {
                        handle_command(command);
                    }

                    while let Ok(command) = rx.try_recv() {
                        handle_command(command);
                    }

                    let popped = {
                        let mut queue_ = queue.lock().unwrap();
                        let result = queue_.pop();
                        drop(queue_);
                        result
                    };

                    if sink.empty() {
                        if let Some(next) = popped {
                            let status_callback_ = status_callback_.clone();

                            println!("{:?}", &next);

                            sink.append(StatusReportingDecoder::new(
                                Decoder::new(BufReader::new(File::open(next.path()).unwrap()))
                                    .unwrap(),
                                Box::new(move |progress, progress_max| {
                                    (status_callback_.lock().unwrap())(PlaybackStatus {
                                        progress: progress as u32,
                                        progress_max: progress_max as u32,
                                        title: next.title().to_string(),
                                        album_artist: next.artist().to_string(),
                                        album_title: next.album().to_string(),
                                    });
                                }),
                            ));
                        }
                    }

                    if exit.load(Ordering::SeqCst) {
                        break;
                    }
                }
                drop(stream);
            }),
            tx,
            status_callback,
            pause_status,
        }
    }

    pub fn add_to_queue(&self, track: Track) {
        self.queue.lock().unwrap().push(track);
    }

    pub fn set_playback_status_callback(
        &self,
        status_callback: Box<impl Fn(PlaybackStatus) + Send + 'static>,
    ) {
        *self.status_callback.lock().unwrap() = status_callback;
    }

    pub fn play(&self) {
        self.tx.send(PlayerCommand::Play).unwrap();
    }

    pub fn pause(&self) {
        self.tx.send(PlayerCommand::Pause).unwrap();
    }

    pub fn stop(&self) {
        self.queue.lock().unwrap().clear();

        self.tx.send(PlayerCommand::Stop).unwrap();
    }

    pub fn is_paused(&self) -> bool {
        self.pause_status.load(Ordering::SeqCst)
    }
}

impl Drop for Player {
    fn drop(&mut self) {
        let _ = self.tx.send(PlayerCommand::Exit);
    }
}
