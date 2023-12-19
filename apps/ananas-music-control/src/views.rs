use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};
use std::error::Error;
use std::{fmt::Debug, sync::Arc};

use crate::gui::controls::button::Button;
use crate::gui::controls::item_scroller::ItemScroller;
use crate::gui::controls::progress_bar::ProgressBar;
use crate::gui::controls::stack_panel::StackPanel;
use crate::gui::controls::text::Text;
use crate::gui::{Control, GuiCommand, Orientation, Padding};
use crate::library::Library;

fn playback_view<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
    TError: Error + Debug + 'static,
>(
    library: Arc<Library>,
    artist: &str,
    album: &str,
) -> Box<dyn Control<TDrawTarget, TError>> {
    let mut stack_panel_children: Vec<Box<dyn Control<_, _>>> = vec![];
    stack_panel_children.push(Box::new(Text::new(
        artist.to_string(),
        18,
        Padding::vertical(10, 10),
    )));
    stack_panel_children.push(Box::new(Text::new(
        album.to_string(),
        20,
        Padding::vertical(10, 10),
    )));
    stack_panel_children.push(Box::new(ProgressBar::new(
        50,
        150,
        5,
        Padding::new(15, 10, 0, 0),
    )));

    Box::new(StackPanel::new(stack_panel_children, Orientation::Vertical))
}

fn artist_view<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
    TError: Error + Debug + 'static,
>(
    library: Arc<Library>,
    artist: &str,
) -> Box<dyn Control<TDrawTarget, TError>> {
    let mut item_scroller_children: Vec<Box<dyn Control<_, _>>> = vec![];

    for album in library.list_albums(artist) {
        let artist = artist.to_string();
        let library = library.clone();

        item_scroller_children.push(Box::new(Button::new(
            Box::new(Text::new(album.clone(), 20, Padding::zero())),
            Padding::new(5, 8, 0, 0),
            Box::new(move |command_tx| {
                command_tx
                    .send(GuiCommand::ReplaceRoot(playback_view(
                        library.clone(),
                        &artist,
                        &album,
                    )))
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
    library: Arc<Library>,
) -> Box<dyn Control<TDrawTarget, TError>> {
    let mut item_scroller_children: Vec<Box<dyn Control<_, _>>> = vec![];
    let mut artists = library.list_artists();

    artists.sort();

    for artist in artists.iter() {
        let artist_clone = artist.clone();

        let library_ = library.clone();
        item_scroller_children.push(Box::new(Button::new(
            Box::new(Text::new(artist.clone(), 20, Padding::zero())),
            Padding::new(5, 8, 0, 0),
            Box::new(move |command_tx| {
                command_tx
                    .send(GuiCommand::ReplaceRoot(artist_view(
                        library_.clone(),
                        &artist_clone,
                    )))
                    .unwrap();
            }),
        )));
    }

    Box::new(ItemScroller::new(item_scroller_children, 3))
}
