use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};
use std::error::Error;
use std::{fmt::Debug, sync::Arc};

use crate::gui::controls::button::Button;
use crate::gui::controls::item_scroller::ItemScroller;
use crate::gui::controls::progress_bar::ProgressBar;
use crate::gui::controls::stack_panel::StackPanel;
use crate::gui::controls::text::Text;
use crate::gui::fonts::FontKind;
use crate::gui::{Control, GuiCommand, Orientation, Padding};
use crate::library::Library;
use crate::playback::Player;

pub struct App {
    library: Arc<Library>,
    player: Arc<Player>,
}

impl App {
    pub fn new(library: Arc<Library>) -> Arc<Self> {
        let player = Player::new();

        Arc::new(Self {
            library,
            player: Arc::new(player),
        })
    }

    fn playback_view<
        TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
        TError: Error + Debug + 'static,
    >(
        self: Arc<Self>,
        artist: &str,
        album: &str,
    ) -> Box<dyn Control<TDrawTarget, TError>> {
        for track in self.library.list_tracks(artist, album) {
            println!("Adding to queue: {:?}", &track);
            self.player.add_to_queue(track);
            println!("Added");
        }

        println!("Play...");
        self.player.play();
        println!("Play done");

        let stack_panel_children: Vec<Box<dyn Control<_, _>>> = vec![
            Box::new(Text::new(artist.to_string(), 18, FontKind::MainText, Padding::vertical(10, 10))),
            Box::new(Text::new(album.to_string(), 20, FontKind::MainText, Padding::vertical(10, 10))),
            Box::new(ProgressBar::new(50, 150, 5, Padding::new(15, 10, 0, 0))),
        ];

        Box::new(StackPanel::new(
            stack_panel_children,
            Orientation::Vertical,
            vec![],
        ))
    }

    fn artist_view<
        TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
        TError: Error + Debug + 'static,
    >(
        self: Arc<Self>,
        library: Arc<Library>,
        artist: &str,
    ) -> Box<dyn Control<TDrawTarget, TError>> {
        let mut item_scroller_children: Vec<Box<dyn Control<_, _>>> = vec![];

        for album in library.list_albums(artist) {
            let artist = artist.to_string();
            let self_ = self.clone();

            item_scroller_children.push(Box::new(Button::new(
                Box::new(Text::new(album.clone(), 20, FontKind::MainText, Padding::zero())),
                Padding::new(5, 8, 0, 0),
                Box::new(move |command_tx| {
                    command_tx
                        .send(GuiCommand::ReplaceRoot(
                            self_.clone().playback_view(&artist, &album),
                        ))
                        .unwrap();
                }),
            )));
        }

        Box::new(ItemScroller::new(item_scroller_children, 3))
    }

    pub fn initial_view<
        TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
        TError: Error + Debug + 'static,
    >(
        self: Arc<Self>,
    ) -> Box<dyn Control<TDrawTarget, TError>> {
        let mut item_scroller_children: Vec<Box<dyn Control<_, _>>> = vec![];
        let mut artists = self.library.list_artists();

        artists.sort();

        for artist in artists.iter() {
            let artist_clone = artist.clone();

            let self_ = self.clone();
            item_scroller_children.push(Box::new(Button::new(
                Box::new(Text::new(artist.clone(), 20, FontKind::MainText, Padding::zero())),
                Padding::new(5, 8, 0, 0),
                Box::new(move |command_tx| {
                    let self_ = self_.clone();
                    let library = self_.library.clone();
                    command_tx
                        .send(GuiCommand::ReplaceRoot(
                            self_.artist_view(library, &artist_clone),
                        ))
                        .unwrap();
                }),
            )));
        }

        Box::new(ItemScroller::new(item_scroller_children, 3))
    }
}
