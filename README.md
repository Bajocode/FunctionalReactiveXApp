# Reactive X Networking App

![Screenshots of the app](media/Header.png)

An example of making network requests using RxSwift, RxCocoa and the TMDB movies API.

#### Install
In a terminal window, cd into the root folder and run `$pod install` to install
`ContourProgressView` [(a progress extension I've built)](https://github.com/Bajocode/ContourProgressView), `RxSwift`, `RxCocoa` and `KingFisher`.

#### GenresViewController
The request is built using a `RxCocoa` `URLRequest` extension and is composed as follows:
1.  First the list of all available genres is fetched
2.  For each genre, the first 2 pages of movies are fetched and merged into 1 Observable
3.  After each movie batch arrives, it is added to the genre to its `.movies` variable, while being alphabetically ordered by name

#### MoviesViewController
A slider is bound to the minimum year of the movie release, which acts as a filter.
