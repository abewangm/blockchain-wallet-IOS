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
        command: (name, height, width) ->
          command = ""
          if (!width)
            width = height
          for scale, suffix of {1: "", 2: "@2x", 3: "@3x"}
            command += "svgexport " + name + ".svg ../Images.xcassets/" + name + ".imageset/" + name + suffix + ".png " + width * scale + ":" + height * scale + "\n"
          command


  grunt.registerTask "default", [
    "shell:psd:welcome_logo:110"
    "shell:psd:blockchain_b:45"
    "shell:psd:blockchain_b_large:90"
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
    "shell:psd:cancel_template:11"
    "shell:psd:thumbs:26"
    "shell:psd:upgrade1:548"
    "shell:psd:upgrade2:548"
    "shell:psd:upgrade3:548"
    "shell:svg:backup_green_circle:40"
    "shell:svg:backup_blue_circle:40"
    "shell:svg:backup_exclamation_mark:40"
    "shell:psd:2fa:75"
    "shell:psd:2fab:50"
    "shell:psd:email:75"
    "shell:psd:emailb:50"
    "shell:psd:key:75"
    "shell:psd:level2icons-security:50"
    "shell:psd:phone:75"
    "shell:psd:phoneb:50"
    "shell:psd:phrase:75"
    "shell:psd:phraseb:50"
    "shell:psd:tor:75"
    "shell:psd:torb:50"
    "shell:psd:keyb:50"
    "shell:psd:security1:50"
    "shell:psd:security2:50"
    "shell:psd:security3:50"
    "shell:svg:check:15"
    "shell:svg:security:26"
    "shell:psd:icon_wallet:26"
    "shell:svg:warning:26"
    "shell:svg:arrow_downward:26"
    "shell:svg:blockchain_wallet_logo:48:232"
    "shell:svg:pencil:26"
    "shell:svg:alert:26"
    "shell:svg:email_square:72:90"
    "shell:svg:lock_large:100:76"
    "shell:svg:mobile_large:100:68"
    "shell:svg:close_large:30"
  ]
