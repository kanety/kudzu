# CHANGELOG

## 1.1.7

* Decode shift_jis with cp932, guess euc-jp subspecific encoding with nkf.
* Add some files for testing various character sets.
* Use mimemagic gem for mime type detection.

## 1.1.6

* Don't apply CK domain normalization to url path.

## 1.1.5

* Don't overwrite default request header.

## 1.1.4

* Don't set encoding by `force_encoding` while getting decoded body.

## 1.1.3

* Remove spaces on right end from link urls.

## 1.1.2

* Remove spaces on left end from link urls.

## 1.1.1

* Apply timeout configs to robots.txt request.

## 1.1.0

* Add malformed url normalization.
* Add `before_fetch` and `after_fetch` callbacks.
* Add `keep_alive_timeout` config.
* Cancel fetching if content-type in request header is matched to filter condition.
* Refactoring.
