path = require "path"
fs = require "fs"
colors = require "colors"
browserify = require "browserify"
chokidar = require "chokidar"
through = require "through"
convertSourceMap = require "convert-source-map" 
UglifyJS = require "uglify-js"

options =
  ignore: /(\/\.|~$)/ 
  watch: true
  debug: true
  minify: false
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
    if ops.build 
      options.build[key] = value for key,value of ops.build

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
      ).require(path.resolve(basedir,i),{entry:true}).bundle {debug:options.debug},(err,src) ->
        if err then console.log "[piping-browser]".bold.yellow,"Error:",err
        else
          if options.minify
            uglify src,path.resolve(basedir,o)#,convertSourceMap.fromSource(src).toObject()
          else 
            fs.writeFileSync path.resolve(basedir,o),src
          console.log "[piping-browser]".bold.yellow,"Built in",Date.now()-start,"ms"

  uglify = (files,output,inputmap) ->
    toplevel = null
    unless typeof files is "string" or files instanceof String
      for file in files
        code = fs.readFileSync file,"utf8"
        toplevel = UglifyJS.parse code,
          filename: file
          toplevel: toplevel
    else
      toplevel = UglifyJS.parse files,
        filename: "bundle.js"

    toplevel.figure_out_scope()
    compressor = UglifyJS.Compressor()
    compressed = toplevel.transform compressor
    compressed.figure_out_scope()
    compressed.compute_char_frequency()
    compressed.mangle_names()
    if options.debug
      mapopts = file: output
      if inputmap then mapopts.orig = inputmap
      map = UglifyJS.SourceMap mapopts
      code = compressed.print_to_string
        source_map: map
      comment = convertSourceMap.fromObject(map.get()).toComment()
      code += "\n" + comment
    else
      code = compressed.print_to_string()
    fs.writeFileSync output,code


  watcher.on "change", (file) ->
    console.log "[piping-browser]".bold.yellow,"File",path.relative(process.cwd(),file),"has changed, rebuilding"
    if options.watch then bundle options.main, options.out

  if options.vendor and options.vendor.files.length and options.vendor.out and options.vendor.path
    files = []
    for file in options.vendor.files
      files.push path.resolve basedir,options.vendor.path,file
    vendor = chokidar.watch files,
      ignored: options.ignore
      ignoreInitial: true
      persistent: true

    vendorBuild = (out) ->
      start = Date.now()
      if options.minify
        uglify files, path.resolve(basedir,out)
      else
        code = ";"
        for file in files
          code += fs.readFileSync(file,"utf8") + ";\n"
        fs.writeFileSync path.resolve(basedir,out),code
      console.log "[piping-browser]".bold.yellow,"Vendor built in",Date.now()-start,"ms"

    vendor.on "change", (file) ->
      console.log "[piping-browser]".bold.yellow,"File",path.relative(process.cwd(),file),"has changed, rebuilding vendor"
      if options.watch then vendorBuild options.vendor.out
    vendorBuild options.vendor.out

  bundle options.main, options.out

