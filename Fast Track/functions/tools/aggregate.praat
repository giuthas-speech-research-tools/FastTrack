
procedure aggregate autorun
  @getSettings

  ## add option to chose to output missing rows or not?
  value_to_collect = 1
  if autorun == 0
  beginPause: "Set Parameters"
    comment: "Indicate your working directory. This folder should contain a folder inside of it"
    comment: "called 'csvs' that contains all of the files you wish to aggregate."
    sentence: "Folder:", folder$
    comment: "How many sections should signal be divided into? 1 returns the overall aggregated value. 3 returns"
    comment: "aggregated results for the first third, midle third, and final third, and so on."
    optionMenu: "Number of formants:", number_of_formants
  			option: "3"
  			option: "4"
    optionMenu: "Number of bins:", number_of_bins
  			option: "1"
  			option: "3"
  			option: "5"
        option: "7"
        option: "9"
        option: "11"
    optionMenu: "Statistic", 1
  	    option: "median"
  	  	option: "mean"
        option: "both"
    choice: "Value to collect", 1
        option: "Observed formant"
        option: "Predicted (smooth) formant"
		#sentence: "Points to measure:", ""
    #real: "number of samples:", 0

  endPause: "Ok", 1
  endif

  ending$ = right$ (folder$,1)
  if ending$ == "/"
    folder$ = folder$ - "/"
  endif
  if ending$ == "\"
    folder$ = folder$ - "\"
  endif
  
  @saveSettings

  points_to_measure = 0
  #if points_to_measure$ <> "" 
  #  points_to_measure = 1
  #  .measure_points = Create Strings as tokens: points_to_measure$, " "
  #  .npoints = Get number of strings
  #endif

  number_of_bins = 1 + (number_of_bins-1)*2
  number_of_formants = number(number_of_formants$)
  createDirectory: folder$ + "/processed_data/"

  if !fileReadable: folder$ + "/file_information.csv"
    @prepareFileInfo: 1
  endif

  .file_info = Read Table from comma-separated file: folder$ + "/file_information.csv"
  .nfiles = Get number of rows

  .winners = Read Table from comma-separated file: folder$ + "/winners.csv"


  ## add columns to ouput table
  Create Table with column names: "output", 0, "file"
  .output = selected ("Table")
  Append column: "duration"
  Append column: "label"
  Append column: "group"
  Append column: "color"
  Append column: "number"
  Append column: "cutoff"
  Append column: "median_f0"
  Append column: "mean_f0"
  # Either add median, mean or both
  if statistic == 1 or statistic == 2 
    @add_average_columns: statistic
  elsif statistic == 3
    @add_average_columns: 1
    @add_average_columns: 2
  endif
   
  .output_counter = 0
  for .iii from 1 to .nfiles

  	selectObject: .winners
		.winner = Get value: .iii, "winner"

    if .winner > 0
      selectObject: .output
      Append row
      .output_counter = .output_counter + 1

      selectObject: .file_info
      .basename$ = Get value: .iii, "file"
      .basename$ = .basename$ - ".wav"

      ## if file readable append row to output and do this
      ## if not do not append and skip 
      .tbl = Read Table from comma-separated file: folder$ + "/csvs/" + .basename$ + ".csv"

      .nframes = Get number of rows
      Append column: "ntime"
      for .j from 1 to .nframes
        tmp = .j / (.nframes/number_of_bins)
        Set numeric value: .j, "ntime", ceiling( tmp )
      endfor
      
      ## section about gettin best cutoff frequency
      .info = Read Strings from raw text file: folder$ + "/infos/" + .basename$ + "_info.txt"
      .tmp$ = Get string: 11
      stringToVector_output# = zero#(number_of_formants)
      @stringToVector: .tmp$
      .cutoff = stringToVector_output#[1] 
      removeObject: .info

      selectObject: .tbl
      .firstFrameTime = Get value: 1, "time"
      .lastFrameTime = Get value: .nframes, "time"
      .duration = .lastFrameTime - .firstFrameTime
      .duration = round(.duration * 1000) / 1000

      selectObject: .output
      Set numeric value: .output_counter, "duration", .duration
      Set numeric value: .output_counter, "cutoff", .cutoff

      selectObject: .tbl
      .median_f0 = Get quantile: "f0", 0.5

      if .median_f0 > 0
        .tmp_tbl = Extract rows where column (number): "f0", "greater than", 0
        .median_f0 = Get quantile: "f0", 0.5
        #.median_f0 = round(.median_f0 * 10) / 10
        removeObject: .tmp_tbl
      endif    
      selectObject: .output
      Set numeric value: .output_counter, "median_f0", .median_f0

      selectObject: .tbl
      .mean_f0 = Get mean: "f0"
      if .mean_f0 > 0
        .tmp_tbl = Extract rows where column (number): "f0", "greater than", 0
        .mean_f0 = Get mean: "f0"
        .mean_f0 = round(.mean_f0 * 10) / 10
        removeObject: .tmp_tbl
      endif    
      selectObject: .output
      Set numeric value: .output_counter, "mean_f0", .mean_f0

      column_label_append$ = ""
      if value_to_collect == 2
        column_label_append$ = "p"
      endif
      
      # Calculate means and/or medians of formants
      if points_to_measure == 0
        for .j from 1 to number_of_bins
          selectObject: .tbl
          .tmp_tbl = Extract rows where column (number): "ntime", "equal to", .j
          # Options are 1 = median, 2 = mean, 3 = both
          for .k from 1 to number_of_formants
            if statistic == 1 
              .median_f'.k''.j' = Get quantile: "f"+string$(.k)+column_label_append$, 0.5
            elsif statistic == 2 
              .mean_f'.k''.j' = Get mean: "f"+string$(.k)+column_label_append$
            elsif statistic == 3
              .median_f'.k''.j' = Get quantile: "f"+string$(.k)+column_label_append$, 0.5
              .mean_f'.k''.j' = Get mean: "f"+string$(.k)+column_label_append$
            endif
          endfor
          removeObject: .tmp_tbl
        endfor
      endif

      selectObject: .output
      Set string value... .output_counter file '.basename$'
      for .j from 1 to number_of_bins
        for .i from 1 to number_of_formants
          if statistic == 1 
            Set numeric value... .output_counter median_f'.i''.j' round(.median_f'.i''.j')
          elsif statistic == 2
            Set numeric value... .output_counter mean_f'.i''.j' round(.mean_f'.i''.j')
          elsif statistic == 3
            Set numeric value... .output_counter median_f'.i''.j' round(.median_f'.i''.j')
            Set numeric value... .output_counter mean_f'.i''.j' round(.mean_f'.i''.j')
          endif
        endfor
      endfor

      selectObject: .file_info
      group$ = Get value: .iii, "group"
      label$ = Get value: .iii, "label"
      color$ = Get value: .iii, "color"
      number$ = Get value: .iii, "number"
      selectObject: .output
      Set string value: .output_counter, "group", group$
      Set string value: .output_counter, "label", label$
      Set string value: .output_counter, "color", color$
      Set string value: .output_counter, "number", number$

      nocheck removeObject: .tbl
    endif
  endfor

  selectObject: .output
  Save as comma-separated file: folder$ + "/processed_data/aggregated_data.csv"
  Rename: "aggregated"

  removeObject: .file_info

endproc

# median: type == 1, mean: type == 2
procedure add_average_columns .type
  for j from 1 to number_of_bins
    for i from 1 to number_of_formants
        if .type == 1
          Append column: "median_f"+string$(i)+string$(j)
        elsif .type == 2
          Append column: "mean_f"+string$(i)+string$(j)
        endif
    endfor
  endfor
endproc
