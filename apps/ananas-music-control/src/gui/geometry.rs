#[derive(Debug, Clone, Copy)]
pub struct Point(pub u32, pub u32);

#[derive(Debug, Clone, Copy)]
pub struct Dimensions {
    width: u32,
    height: u32,
}

impl Dimensions {
    pub fn new(width: u32, height: u32) -> Self {
        Self { width, height }
    }

    pub fn width(&self) -> u32 {
        self.width
    }

    pub fn height(&self) -> u32 {
        self.height
    }
}

#[derive(Debug, Clone)]
pub struct Rectangle {
    position: Point,
    dimensions: Dimensions,
}

impl Rectangle {
    pub fn new(position: Point, dimensions: Dimensions) -> Self {
        Self {
            position,
            dimensions,
        }
    }

    pub fn position(&self) -> Point {
        self.position
    }

    pub fn dimensions(&self) -> Dimensions {
        self.dimensions
    }

    pub fn contains(&self, position: Point) -> bool {
        position.0 > self.position.0
            && position.0 < self.position.0 + self.dimensions.width
            && position.1 > self.position.1
            && position.1 < self.position.1 + self.dimensions.height
    }
}
