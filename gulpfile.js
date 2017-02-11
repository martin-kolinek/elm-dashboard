var gulp = require('gulp');
var elm = require('gulp-elm');
var plumber = require('gulp-plumber');
var del = require('del');
var browserSync = require('browser-sync');

// builds elm files and static resources (i.e. html and css) from src to dist folder
var paths = {
    dest: 'dist',
    fontDest: 'dist/fonts',
    elm: 'src/*.elm',
    staticAssets: 'src/*.{html,css}',
    fonts: 'src/fonts/*'
};

gulp.task('clean', function(cb) {
    del([paths.dest], cb);
});

gulp.task('elm-init', elm.init);

gulp.task('elm', ['elm-init'], function() {
    return gulp.src(paths.elm)
        .pipe(plumber())
        .pipe(elm())
        .pipe(gulp.dest(paths.dest))
        .pipe(browserSync.stream());
});

gulp.task('staticAssets', function() {
    return gulp.src(paths.staticAssets)
        .pipe(plumber())
        .pipe(gulp.dest(paths.dest))
        .pipe(browserSync.stream());
});

gulp.task('fonts', function() {
    return gulp.src(paths.fonts)
        .pipe(plumber())
        .pipe(gulp.dest(paths.fontDest))
        .pipe(browserSync.stream());
});

gulp.task('browser-sync', function() {
    browserSync.init({
        server: {
            baseDir: "dist/"
        },
        notify: false
    });
});

gulp.task('watch', function() {
    gulp.watch(paths.elm, ['elm']);
    gulp.watch(paths.staticAssets, ['staticAssets']);
    gulp.watch(paths.fonts, ['fonts']);
});

gulp.task('build', ['elm', 'staticAssets', 'fonts']);
gulp.task('dev', ['build', 'browser-sync', 'watch']);
gulp.task('default', ['build']);
