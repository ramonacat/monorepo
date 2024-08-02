const { src, dest, parallel, watch } = require('gulp');
const typescript = require('gulp-typescript');
const sass = require('gulp-sass')(require('sass'));
const postcss = require('gulp-postcss');

const destination = () => dest('public/assets/');

function ts() {
    return src('src-frontend/js/main.ts')
        .pipe(typescript())
        .pipe(destination());
}

function css() {
    return src('src-frontend/css/main.scss')
        .pipe(sass().on('error', sass.logError))
        .pipe(postcss([
            require('postcss-modules')
        ]))
        .pipe(destination());
}

exports.default = parallel(
    css,
    ts
);

exports.watch = function () {
    watch('src-frontend/css/**/*.scss', css);
    watch('src-frontend/js/**/*.ts', ts);
}