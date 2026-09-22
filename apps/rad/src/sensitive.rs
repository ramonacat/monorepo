use std::{
    fmt::Debug,
    ops::{Deref, DerefMut},
};

pub struct Sensitive<T>(T);

impl<T> Sensitive<T> {
    pub fn new(inner: T) -> Self {
        Self(inner)
    }
}

impl<T> Debug for Sensitive<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_tuple("Sensitive").finish_non_exhaustive()
    }
}

impl<T: Clone> Clone for Sensitive<T> {
    fn clone(&self) -> Self {
        Self(self.0.clone())
    }
}

impl<T> DerefMut for Sensitive<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl<T> Deref for Sensitive<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
