var gulp = require('gulp');
var elm = require('gulp-elm');
var plumber = require('gulp-plumber');
var del = require('del');
var browserSync = require('browser-sync');

// builds elm files and static resources (i.e. html and css) from src to dist folder
var paths = {
    dest: 'dist',
    elm: 'src/*.elm',
    staticAssets: 'src/*.{html,css}'
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
});

gulp.task('build', ['elm', 'staticAssets']);
gulp.task('dev', ['build', 'browser-sync', 'watch']);
gulp.task('default', ['build']);
