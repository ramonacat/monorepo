use colored::{Color, Colorize as _};

use crate::todo::Todo;

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

pub async fn execute(server_url: &str) {
    let todo_client = ratlib::todo::client::Client::new(server_url);

    let doing: Vec<Todo> = todo_client.find_doing().await;

    if !doing.is_empty() {
        println!("{}", "Doing: ".color(Color::Yellow).bold());

        for todo in doing {
            let todo = render_todo(&todo);

            println!("{todo}");
        }

        println!();
    }

    println!("{}", "Todo: ".color(Color::Red).bold());
    let ready_to_do: Vec<Todo> = todo_client.find_ready_to_do().await;

    for todo in ready_to_do {
        let todo = render_todo(&todo);

        println!("{todo}");
    }
}
