const { src, dest, parallel, series, watch } = require('gulp');
const typescript = require('gulp-typescript');
const sass = require('gulp-sass')(require('sass'));
const postcss = require('gulp-postcss');
const {exec} = require('child_process');

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

const cssModulesPhp = async function(cb: (arg0: any) => void) {
    await exec('php bin/generate-css-modules.php',function (err: any, stdout: any, stderr: any) {
        console.log(stdout);
        console.log(stderr);
        cb(err);
    });
}

exports.default = parallel(
    series(css, cssModulesPhp),
    ts
);

exports.watch = function () {
    watch('src-frontend/css/**/*.scss', series(css, cssModulesPhp));
    watch('src-frontend/js/**/*.ts', ts);
}