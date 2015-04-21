require! \fs
require! \stylus
require! \LiveScript
require! \slm
require! \slm-markdown
require! \deasync
require! \browserify
require! \watchify
require! \stream-cache
require! \string-to-stream
require! \js-string-escape

# todo: put into class, add .at(path)

module.exports = { page, style, script, app, reloader }

# junglist = module.exports = new Middleware!
# junglist.Middleware = Middleware
# junglist.at = (path) ->
#   new Middleware path

register-slm-extensions!

function page filename
  (req, res) ->
    out <- html "pages", filename, {}
    res.end out

function html dir, filename, model, complete
  err, file <- fs.read-file "#dir/#filename.slm", "utf8"
  if err then return complete string err
  html = slm.compile file, filename: "#dir/#filename.slm"
  complete html model

function style filename
  (req, res) ->
    err, css <- render-style filename
    if err then return res.end string err
    res.type "text/css"
    res.end css

function script filename
  (req, res) ->
    err, contents <- fs.read-file "scripts/#filename.ls", \utf8
    if err then return res.end string err
    js = compile-script contents
    res.type "text/javascript"
    res.end js

function app filename, options
  settings =
    transforms: []
  settings <<< options
  cache = null
  bundler = watchify browserify "apps/#filename.ls"
  bundler.transform \liveify
  bundler.transform \debowerify
  for t in settings.transforms
    bundler.transform t
  bundler.on \update -> build!
  bundler.on \bundle ->
    if settings.update
      settings.update!
  build!
  return middleware

  function build
    cache := new stream-cache
    bundler.bundle!
      .on \error, (ex) ->
        ex = js-string-escape string ex
        ex = "throw \"Bundle error: '#ex';\""
        string-to-stream(ex).pipe cache
      .pipe cache

  function middleware req, res
    res.type "text/javascript"
    cache.pipe res

function reloader poll-path
  poll = 1000ms
  version = Date.now!
  middleware.reload = reload
  middleware.live-reload = live-reload
  return middleware

  function middleware req, res, next
    switch req.method
    | \GET =>
      res.type "text/javascript"
      res.end live-reload!
    | \POST =>
      res.type "application/json"
      res.end string version
    | otherwise => next!

  function reload
    version := Date.now!

  function live-reload
    """
      (function() {
        var version = "#version";
        function refresh() {
          var req = new XMLHttpRequest();
          req.onreadystatechange = function() {
            if (req.readyState === 4) {
              if (req.status === 200) {
                newVersion = req.responseText;
                if (version !== null && version !== newVersion) {
                  return document.location.reload();
                }
                version = newVersion;
              }
              setTimeout(refresh, #poll);
            }
          };
          req.open("POST", "#poll-path", true);
          try {
            req.send();
          }
          catch (e) { }
        }
        setTimeout(refresh, #poll);
      })();
    """

function render-style filename, complete
  err, contents <- fs.read-file "styles/#filename.styl", \utf8
  if err then return complete string err
  compile-style contents, filename, complete

render-style-sync = deasync render-style

function register-slm-extensions
  slm-markdown.register slm.template
  slm.template.register-embedded-function "include", (body) ->
    includes = body.trim!.split "\n"
    output = ""
    for include in includes
      params = include.trim!.split /\s+/
      if params.length > 1
        command = params.0
        filename = params.1
      else
        command = "plain"
        filename = params.0
      switch command
      | "style" =>
        css = render-style-sync filename
        output += "<style>#css</style>"
      | "script" =>
        contents = fs.read-file-sync "scripts/#filename.ls", \utf8
        js = compile-script contents
        output += "<script>#js</script>"
      | "plain" =>
        output += fs.read-file-sync "pages/#filename", \utf8
    output
  slm.template.register-embedded-function "style", (body) ->
    css = compile-style-sync body, null
    "<style>#css</style>"
  slm.template.register-embedded-function "script", (body) ->
    js = compile-script body
    "<script>#js</script>"

# todo: minify
function compile-script ls
  LiveScript.compile ls, header: false

function compile-style styl, filename, complete
  sheet = stylus styl
    ..set \compress, true
    ..set \filename, "styles/#filename.styl"
    ..define \embed-font, embed-font
  err, css <- sheet.render
  if err then return complete string err
  complete null, css

compile-style-sync = deasync compile-style

function embed-font {val}
  buffer = fs.read-file-sync "fonts/#val.woff"
  buffer = buffer.to-string \base64
  "data:application/font-woff;base64,#buffer"

function string x
  x and x.to-string!
