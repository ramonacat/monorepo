use std::{
    fmt::Debug,
    ops::{Deref, DerefMut},
    str::FromStr,
};

use serde::Deserialize;

#[derive(Deserialize)]
#[serde(transparent)]
pub struct Sensitive<T>(T);

impl<T> Sensitive<T> {
    pub fn new(inner: T) -> Self {
        Self(inner)
    }

    pub fn unseal(self) -> T {
        self.0
    }

    pub fn as_ref(&self) -> Sensitive<&T> {
        Sensitive(&self.0)
    }

    pub fn map<'a, Return: 'a>(self, f: impl FnOnce(T) -> Return) -> Sensitive<Return> {
        Sensitive(f(self.0))
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

impl<T: FromStr> FromStr for Sensitive<T> {
    type Err = <T as FromStr>::Err;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Ok(Self(<T as FromStr>::from_str(s)?))
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
