path = require "path"
fs = require "fs"
colors = require "colors"
browserify = require "browserify"
chokidar = require "chokidar"
through = require "through"
convertSourceMap = require "convert-source-map" 

options =
  ignore: /(\/\.|~$)/ 
  watch: true
  debug: true
  build:
    "coffee": (file,data) ->
        coffee = require "coffee-script"
        compiled = coffee.compile data, {sourceMap: true, generatedFile: true, inline: true}
        comment = convertSourceMap.fromJSON(compiled.v3SourceMap).setProperty("sources", [ file ]).toComment()
        return compiled.js + "\n" + comment


module.exports = (ops,out) ->
  if (typeof ops is "string" or ops instanceof String) and (typeof out is "string" or out instanceof String)
    options.main = ops
    options.out = out
  else
    options[key] = value for key,value of ops when key isnt "build"
    if opts.build 
      options.build[key] = value for key,value of opts.build

  basedir = path.dirname module.parent.filename
  
  watcher = chokidar.watch path.resolve(basedir,options.main),
    ignored: options.ignore
    ignoreInitial: true
    persistent: true
  bundle = (i,o) ->
    start = Date.now()
    browserify().transform((file) ->
        watcher.add file
        for ext,func of options.build
          if RegExp("\.#{ext}$").test file
            data = ""
            write = (buf) -> data += buf
            end = -> 
              @queue func(file,data)
              @queue null
            return through write, end
        return through()
      ).require(path.resolve(basedir,i),{entry:true}).bundle(debug:options.debug)
      .on("error", (err) -> console.log "[piping-browser]".bold.yellow,"Error:",err)
      .on("end",-> console.log "[piping-browser]".bold.yellow,"Built in",Date.now()-start,"ms")
      .pipe fs.createWriteStream path.resolve(basedir,o)


  watcher.on "change", (file) ->
    console.log "[piping-browser]".bold.yellow,"File",path.relative(process.cwd(),file),"has changed, rebuilding"
    if options.watch then bundle options.main, options.out

  bundle options.main, options.out

