use std::{fmt::Debug, sync::Arc};
use std::error::Error;
use embedded_graphics::{draw_target::DrawTarget, pixelcolor::BinaryColor};

use crate::gui::controls::item_scroller::ItemScroller;
use crate::gui::{Control, Padding, GuiCommand};
use crate::gui::controls::button::Button;
use crate::gui::controls::text::Text;
use crate::library::Library;



fn artist_view<
    TDrawTarget: DrawTarget<Color = BinaryColor, Error = TError> + 'static,
    TError: Error + Debug + 'static,
>(
    library: Arc<Library>,
    artist: &str,
) -> Box<dyn Control<TDrawTarget, TError>> {
    let mut item_scroller_children: Vec<Box<dyn Control<_, _>>> = vec![];

    for album in library.list_albums(artist) {
        item_scroller_children.push(Box::new(Button::new(
            Box::new(Text::new(album.clone(), 20)),
            Padding::new(5, 8, 0, 0),
            Box::new(move |_command_tx| {
                println!("{:?}", album);
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
            Box::new(Text::new(artist.clone(), 20)),
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