use std::fs::File;
use std::io::BufReader;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{channel, Sender};
use std::sync::Arc;
use std::thread::JoinHandle;
use std::time::Duration;
use std::{path::PathBuf, sync::Mutex, thread};

use cpal::traits::HostTrait;
use rodio::{Decoder, OutputStream, Sink};

enum PlayerCommand {
    Play,
    Pause,
    Stop,
    Exit,
}

pub struct PlaybackStatus {}

impl PlaybackStatus {
    pub fn elapsed(&self) -> u32 {
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs() as u32
            % 123
    }
    pub fn total_length(&self) -> u32 {
        123
    }
}

type StatusCallback = Arc<Mutex<Box<dyn Fn(PlaybackStatus) + Send>>>;

pub struct Player {
    queue: Arc<Mutex<Vec<PathBuf>>>,
    queue_thread: JoinHandle<()>,
    tx: Sender<PlayerCommand>,
    status_callback: StatusCallback,
}

impl Player {
    pub fn new() -> Self {
        let queue = Arc::new(Mutex::new(vec![]));
        let queue_ = queue.clone();

        let status_callback: StatusCallback = Arc::new(Mutex::new(Box::new(|_| {})));
        let status_callback_ = status_callback.clone();

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
                    PlayerCommand::Play => sink.play(),
                    PlayerCommand::Pause => sink.pause(),
                    PlayerCommand::Stop => sink.stop(),
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

                    {
                        println!("Calling status callback");
                        (status_callback_.lock().unwrap())(PlaybackStatus {});
                    }

                    if let Some(next) = popped {
                        sink.append(
                            Decoder::new(BufReader::new(File::open(next).unwrap())).unwrap(),
                        );
                    }

                    if exit.load(Ordering::SeqCst) {
                        break;
                    }
                }
                drop(stream);
            }),
            tx,
            status_callback,
        }
    }

    pub fn add_to_queue(&self, path: PathBuf) {
        self.queue.lock().unwrap().push(path);
    }

    pub fn play(&self, status_callback: Box<impl Fn(PlaybackStatus) + Send + 'static>) {
        self.tx.send(PlayerCommand::Play).unwrap();
        *self.status_callback.lock().unwrap() = status_callback;
    }

    pub fn pause(&self) {
        self.tx.send(PlayerCommand::Pause).unwrap();
    }

    pub fn stop(&self) {
        self.queue.lock().unwrap().clear();

        self.tx.send(PlayerCommand::Stop).unwrap();
    }
}
