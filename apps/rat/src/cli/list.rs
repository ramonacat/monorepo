use colored::{Color, Colorize as _};

use crate::{todo::store::Store, todo::Todo};

pub fn render_todo(todo: &Todo) -> String {
    let mut depends_string = "reqs: ".to_string();
    for requirement in todo.requirements() {
        depends_string += &format!("{requirement} ");
    }

    format!(
        "{:>10} {:>10}     {} {} {}",
        todo.id().to_string().color(Color::BrightBlack),
        todo.priority().to_string(),
        todo.title(),
        if todo.requirements().is_empty() {
            "".color(Color::Blue)
        } else {
            depends_string.color(Color::Blue)
        },
        format!("{}min", todo.estimate().as_secs() / 60).color(Color::BrightYellow)
    )
}

pub fn execute(todo_store: &Store) {
    let doing = todo_store.find_doing();

    if !doing.is_empty() {
        println!("{}", "Doing: ".color(Color::Yellow).bold());

        for todo in doing {
            let todo = render_todo(&todo);

            println!("{todo}");
        }

        println!();
    }

    println!("{}", "Todo: ".color(Color::Red).bold());
    let ready_to_do = todo_store.find_ready_to_do();

    for todo in ready_to_do {
        let todo = render_todo(&todo);

        println!("{todo}");
    }
}
