use std::fs::File;
use std::io::BufReader;
use std::sync::Arc;
use std::thread::JoinHandle;
use std::time::Duration;
use std::{path::PathBuf, sync::Mutex, thread};

use cpal::traits::HostTrait;
use rodio::{Decoder, DeviceTrait, OutputStream, Sink};

pub struct Player {
    queue: Arc<Mutex<Vec<PathBuf>>>,
    queue_thread: JoinHandle<()>,
}

impl Player {
    pub fn new() -> Self {
        let queue = Arc::new(Mutex::new(vec![]));
        let queue_ = queue.clone();

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

                loop {
                    sink.sleep_until_end();

                    let popped = {
                        let mut queue_ = queue.lock().unwrap();
                        let result = queue_.pop();
                        drop(queue_);
                        result
                    };

                    if let Some(next) = popped {
                        sink.append(
                            Decoder::new(BufReader::new(File::open(next).unwrap())).unwrap(),
                        );
                        sink.play();
                    } else {
                        // FIXME: This is dumb dumb, we should wait till the queue has an item, but the sleep gets the job done for now
                        thread::sleep(Duration::from_millis(100));
                    }

                    // FIXME this is a dummy condition that doesn't make any sense to trick the compiler into thinking that this loop ends, we should remove it and replace with something that actually makes sense
                    if sink.len() > 1024 {
                        break;
                    }
                }
                drop(stream);
            }),
        }
    }

    pub fn add_to_queue(&self, path: PathBuf) {
        self.queue.lock().unwrap().push(path);
    }

    pub fn play(&self) {
        // FIXME: send a command here
        // self.sink.play();
    }

    pub fn pause(&self) {
        // FIXME: send a command here
        // self.sink.pause();
    }

    pub fn stop(&self) {
        // FIXME: send a command here to stop the playback
        self.queue.lock().unwrap().clear();

        // self.sink.stop();
    }
}
