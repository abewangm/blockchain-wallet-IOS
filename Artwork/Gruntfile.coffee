module.exports = (grunt) ->
  grunt.loadNpmTasks('grunt-shell')
  
  grunt.initConfig
    shell:
      psd:
        command: (name, height) ->
          command = ""
          for scale, suffix of {1: "", 2: "@2x", 3: "@3x"}
            command += "convert -resize x" + height * scale + " " + name + ".psd[1] ../Images.xcassets/" + name + ".imageset/" + name + suffix + ".png\n"   
          command
          
      svg: 
        command: (name, height) ->
          command = ""
          for scale, suffix of {1: "", 2: "@2x", 3: "@3x"}
            command += "svgexport " + name + ".svg ../Images.xcassets/" + name + ".imageset/" + name + suffix + ".png " + height * scale + ":" + height * scale + "\n"   
          command
          
    
  grunt.registerTask "default", [
    "shell:psd:welcome_logo:110"
    "shell:psd:blockchain_b:45"
    "shell:psd:blockchain_logo:15"
    "shell:psd:blockchain_logo_small:11"
    "shell:psd:transaction_pending:11"
    "shell:psd:sidebar:18"
    "shell:psd:qrscanner:18"
    "shell:psd:icon_backup_complete:26"
    "shell:psd:icon_backup_incomplete:26"
    "shell:psd:icon_merchant:26"
    "shell:psd:icon_support:26"
    "shell:psd:icon_upgrade:26"
    "shell:psd:icon_share:25"
    "shell:psd:cancel:11"
    "shell:psd:thumbs:26"
    "shell:svg:backup_green_circle:40"
    "shell:svg:backup_blue_circle:40"
    "shell:svg:backup_exclamation_mark:40"
  ]
