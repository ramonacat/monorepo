use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};
use std::error::Error;
use std::marker::PhantomData;
use std::sync::mpsc::Sender;
use std::{fmt::Debug, sync::Arc};

use crate::gui::controls::button::Button;
use crate::gui::controls::item_scroller::ItemScroller;
use crate::gui::controls::progress_bar::ProgressBar;
use crate::gui::controls::stack_panel::StackPanel;
use crate::gui::controls::text::Text;
use crate::gui::fonts::FontKind;
use crate::gui::{Control, GuiCommand, Orientation, Padding, StackUnitDimension};
use crate::library::Library;
use crate::playback::{PlaybackStatus, Player};

type BackCallback<TDrawTarget, TError> =
    Option<Box<dyn FnMut(Sender<GuiCommand<TDrawTarget, TError>>)>>;

pub struct App<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
    TError: Error + Debug + 'static,
> {
    library: Arc<Library>,
    player: Arc<Player>,
    draw_target: PhantomData<TDrawTarget>,
}

impl<
        TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
        TError: Error + Debug + 'static,
    > App<TDrawTarget, TError>
{
    pub fn new(library: Arc<Library>) -> Arc<Self> {
        let player = Player::new();

        Arc::new(Self {
            library,
            player: Arc::new(player),
            draw_target: PhantomData,
        })
    }

    fn playback_view(
        self: Arc<Self>,
        artist: &str,
        album: &str,
    ) -> Box<dyn Control<TDrawTarget, TError>> {
        for track in self.library.list_tracks(artist, album) {
            self.player.add_to_queue(track);
        }

        let track_title = Text::new(
            "".to_string(),
            15,
            FontKind::MainText,
            Padding::vertical(5, 5),
        );
        let progress_bar = ProgressBar::new(0, 150, 5, Padding::new(5, 5, 0, 0));

        let track_title_text = track_title.text();

        let progress = progress_bar.progress();
        let progress_max = progress_bar.progress_max();

        self.player
            .play(Box::new(move |playback_status: PlaybackStatus| {
                track_title_text.send(playback_status.title().to_string());
                progress.send(playback_status.elapsed());
                progress_max.send(playback_status.total_length());
            }));

        let stack_panel_children: Vec<Box<dyn Control<_, _>>> = vec![
            Box::new(Text::new(
                artist.to_string(),
                15,
                FontKind::MainText,
                Padding::vertical(3, 3),
            )),
            Box::new(Text::new(
                album.to_string(),
                17,
                FontKind::MainText,
                Padding::vertical(3, 3),
            )),
            Box::new(track_title),
            Box::new(progress_bar),
        ];

        let stack_panel = Box::new(StackPanel::new(
            stack_panel_children,
            Orientation::Vertical,
            vec![],
        ));

        let self_ = self.clone();
        let artist = artist.to_string();
        self.wrapping_view(
            stack_panel,
            Some(Box::new(move |tx| {
                tx.send(GuiCommand::ReplaceRoot(self_.clone().artist_view(&artist)))
                    .unwrap();
            })),
        )
    }

    fn artist_view(self: Arc<Self>, artist: &str) -> Box<dyn Control<TDrawTarget, TError>> {
        let mut item_scroller_children: Vec<Box<dyn Control<_, _>>> = vec![];

        for album in self.library.list_albums(artist) {
            let artist = artist.to_string();
            let self_ = self.clone();

            item_scroller_children.push(Box::new(Button::new(
                Box::new(Text::new(
                    album.clone(),
                    20,
                    FontKind::MainText,
                    Padding::zero(),
                )),
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

        let scroller = Box::new(ItemScroller::new(item_scroller_children, 3));

        self.wrapping_view(scroller, None)
    }

    pub fn initial_view(self: Arc<Self>) -> Box<dyn Control<TDrawTarget, TError>> {
        let mut item_scroller_children: Vec<Box<dyn Control<_, _>>> = vec![];
        let mut artists = self.library.list_artists();

        artists.sort();

        for artist in artists.iter() {
            let artist_clone = artist.clone();

            let self_ = self.clone();
            item_scroller_children.push(Box::new(Button::new(
                Box::new(Text::new(
                    artist.clone(),
                    15,
                    FontKind::MainText,
                    Padding::zero(),
                )),
                Padding::new(3, 6, 0, 0),
                Box::new(move |command_tx| {
                    let self_ = self_.clone();

                    command_tx
                        .send(GuiCommand::ReplaceRoot(self_.artist_view(&artist_clone)))
                        .unwrap();
                }),
            )));
        }

        let scroller = Box::new(ItemScroller::new(item_scroller_children, 3));

        self.wrapping_view(scroller, None)
    }

    pub fn wrapping_view(
        self: Arc<Self>,
        content: Box<dyn Control<TDrawTarget, TError>>,
        back: BackCallback<TDrawTarget, TError>,
    ) -> Box<dyn Control<TDrawTarget, TError>> {
        let mut navigation_buttons: Vec<Box<dyn Control<_, _>>> = vec![];
        let self_ = self.clone();
        navigation_buttons.push(Box::new(Button::new(
            Box::new(Text::new(
                "🏠".to_string(),
                25,
                FontKind::Emoji,
                Padding::zero(),
            )),
            Padding::zero(),
            Box::new(move |tx| {
                tx.send(GuiCommand::ReplaceRoot(self_.clone().initial_view()))
                    .unwrap();
            }),
        )));

        if let Some(back_action) = back {
            navigation_buttons.push(Box::new(Button::new(
                Box::new(Text::new(
                    "⬅️".to_string(),
                    25,
                    FontKind::Emoji,
                    Padding::zero(),
                )),
                Padding::zero(),
                back_action,
            )));
        }

        let navigation = StackPanel::new(navigation_buttons, Orientation::Horizontal, vec![]);
        let stack_panel = StackPanel::new(
            vec![content, Box::new(navigation)],
            Orientation::Vertical,
            vec![StackUnitDimension::Stretch, StackUnitDimension::Pixel(30)],
        );

        Box::new(stack_panel)
    }
}
