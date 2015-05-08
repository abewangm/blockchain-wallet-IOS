module.exports = (grunt) ->
  grunt.loadNpmTasks('grunt-shell')
  
  grunt.initConfig
    shell:
      convert:
        command: (name, height) ->
          command = ""
          for scale, suffix of {1: "", 2: "@2x", 3: "@3x"}
            command += "convert -resize x" + height * scale + " " + name + ".psd[1] " + "../Images.xcassets/" + name + ".imageset/" + name + suffix + ".png\n"   
          command
    
  grunt.registerTask "default", [
    "shell:convert:blockchain_logo:15"
    "shell:convert:map:20"
    "shell:convert:transaction_pending:11"
    "shell:convert:sidebar:18"
    "shell:convert:qrscanner:18"
  ]