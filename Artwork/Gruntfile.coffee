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
    "shell:psd:blockchain_logo:15"
    "shell:psd:transaction_pending:11"
    "shell:psd:sidebar:18"
    "shell:psd:qrscanner:18"
    "shell:psd:icon_backup_complete:26"
    "shell:psd:icon_backup_incomplete:26"
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
    "shell:psd:phone:75"
    "shell:psd:phoneb:50"
    "shell:psd:phrase:75"
    "shell:psd:phraseb:50"
    "shell:psd:tor:75"
    "shell:psd:torb:50"
    "shell:psd:keyb:50"
    "shell:svg:check:15"
    "shell:svg:security:26"
    "shell:svg:warning:26"
    "shell:svg:arrow_downward:26"
    "shell:svg:blockchain_wallet_logo:48:232"
    "shell:svg:pencil:26"
    "shell:svg:alert:26"
    "shell:svg:email_square:52:65"
    "shell:svg:lock_large:72:55"
    "shell:svg:mobile_large:72:49"
    "shell:svg:help:36"
    "shell:svg:keypad:255:375"
    "shell:svg:lock:36"
    "shell:svg:logout:36"
    "shell:svg:merchant:36"
    "shell:svg:receive:24"
    "shell:svg:send:24"
    "shell:svg:settings:36"
    "shell:svg:tx:24"
    "shell:svg:wallet:36"
    "shell:svg:close_large:30"
    "shell:svg:logo:45"
    "shell:svg:logo_both:110:130"
    "shell:svg:receive_blue:24"
    "shell:svg:send_blue:24"
    "shell:svg:tx_blue:24"
    "shell:svg:text:32:281"
  ]
