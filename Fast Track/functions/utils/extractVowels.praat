

# saves sounds in folder$
# requires vwlTbl, segment_tier, word_tier

procedure extractVowels:

  selectObject: tg
  nIntervals = Get number of intervals: segment_tier
  segmentcount = 0
  output_file_count = 0

  selectObject: snd
  snd_duration = Get duration
  
  ## loop to go through all segment intervals
  for i from 1 to nIntervals
    selectObject: tg
    vowel$ = Get label of interval: segment_tier, i
    
    if stress == 1
      stress$ = right$ (vowel$, 1)
      len = length (vowel$)
      vowel$ = left$ (vowel$, len-1)
    endif

    ## get info about current (and previous and next) word and segment
    vowelStart = Get start time of interval: segment_tier, i
    vowelEnd = Get end time of interval: segment_tier, i
    if word_tier > 0
      wordNum = Get interval at time: word_tier, (vowelStart+vowelEnd)/2
      word$ = Get label of interval: word_tier, wordNum
      wordStart = Get start time of interval: word_tier, wordNum
      wordEnd = Get end time of interval: word_tier, wordNum
    endif

    ## check if vowel should be analyzed and extracted
    analyze = 0
    extract = 0

    selectObject: vwl_tbl
    num = Search column: "label", vowel$

    if num > 0
      analyze = 1
      extract = 1

      if stress == 1
        selectObject: stresses
        analyze = Has word: stress$
        extract = analyze
      endif
    endif

    ## check for skippable word here
    if words_to_skip = 1
      selectObject: wordTbl
      num = Search column: "word", word$
      if num > 0
        analyze = 0
        extract = 0
      endif
    endif

    ## make this into table object. stress_to_extract$
    ## look for label in column. extract of yes. thats it. 
    
    ## check duration and omit tier
    if omit_tier > 0
      selectObject: tg
      omitnum = Get interval at time: omit_tier, (vowelStart+vowelEnd)/2
      omit$ = Get label of interval: omit_tier, omitnum
      if omit$ <> ""
        extract = 0
      endif
    endif    
    
    ## check that vowel is longer than 30 ms
    if (vowelEnd-vowelStart) < 0.03
      extract = 0    
    endif

    ## check that the vowel doesnt occur after the sound has ended. 
    if (vowelEnd > snd_duration)
      analyze = 0
    endif

    ## if segment should be analyzed....
    ## add functionality to not extract but add to omit column, and not to file info!
    if analyze == 1
    
      selectObject: tg

      next_sound$ = "--"
      previous_sound$ = "--"
      if i > 1
        previous_sound$ = Get label of interval: segment_tier, i-1
        if previous_sound$ == ""
          previous_sound$ = "-"
        endif
      endif
      if i < nIntervals
        next_sound$ = Get label of interval: segment_tier, i+1
        if next_sound$ == ""
          next_sound$ = "-"
        endif
      endif

      if comment_tier1 > 0
        commentNum1 = Get interval at time: comment_tier1, (vowelStart+vowelEnd)/2
        comment1$ = Get label of interval: comment_tier1, commentNum1
      endif
      if comment_tier2 > 0
        commentNum2 = Get interval at time: comment_tier2, (vowelStart+vowelEnd)/2
        comment2$ = Get label of interval: comment_tier2, commentNum2
      endif
      if comment_tier3 > 0
        commentNum3 = Get interval at time: comment_tier3, (vowelStart+vowelEnd)/2
        comment3$ = Get label of interval: comment_tier3, commentNum3
      endif

      ## only do this block if there is a word tier
      if word_tier > 0
        next_word$ = "-"
        previous_word$ = "-"
        if wordNum > 1
          previous_word$ = Get label of interval: word_tier, wordNum-1
          if previous_word$ == ""
            previous_word$ = "-"
          endif
        endif
        maxwords = Get number of intervals: word_tier
        if wordNum < maxwords
          next_word$ = Get label of interval: word_tier, wordNum+1
          if next_word$ == ""
            next_word$ = "-"
          endif
        endif
      endif
      

      ##### Sound extraction and adding to file info
      ## extract and save sound

      if extract == 1

        output_file_count = output_file_count + 1
        selectObject: snd
        snd_small = Extract part: vowelStart - buffer, vowelEnd + buffer, "rectangular", 1, "no"
        if output_file_count > 999
          filename$ = basename$ + "_" + string$(output_file_count)
        endif
        if output_file_count > 99 and output_file_count < 1000
          filename$ = basename$ + "_0" + string$(output_file_count)
        endif
        if output_file_count > 9 and output_file_count < 100
          filename$ = basename$ + "_00" + string$(output_file_count)
        endif
        if output_file_count < 10
          filename$ = basename$ + "_000" + string$(output_file_count)
        endif

        if maintain_separate == 1
          Save as WAV file: output_folder$ + "/" + basename$ + "/" + filename$ + ".wav"
        endif
        if maintain_separate == 0
          Save as WAV file: output_folder$ + "/sounds/" + filename$ + ".wav"
        endif
        removeObject: snd_small
            
        selectObject: vwl_tbl
        spot = Search column: "label", vowel$
        tmp_clr$ = Get value: spot, "color"

        selectObject: file_info
        Append row
        # Writing the last line instead of the line numbered output_file_count 
        # so that if this is not the first file we are extracting vowels from, 
        # data is still saved.
        line_number = Get number of rows
        Set string value: line_number, "file", filename$ + ".wav"
        Set string value: line_number, "label", vowel$
        Set numeric value: line_number, "group", spot
        Set string value: line_number, "color", tmp_clr$
        Set numeric value: line_number, "number", output_file_count
      endif

    
      segmentcount = segmentcount + 1
      ## write information to table
      selectObject: tbl
      Append row
      line_number = Get number of rows
      Set string value: line_number, "inputfile", basename$
      Set string value: line_number, "outputfile", "--"
      if extract == 1
        Set string value: line_number, "outputfile", filename$
      endif

      Set numeric value: line_number, "duration", vowelEnd-vowelStart
      Set numeric value: line_number, "start", vowelStart
      Set numeric value: line_number, "end", vowelEnd
      Set string value: line_number, "vowel", vowel$
      Set numeric value: line_number, "interval", i
      Set string value: line_number, "previous_sound", previous_sound$
      Set string value: line_number, "next_sound", next_sound$

      if stress == 1
        Set string value: line_number, "stress", stress$
      endif

      omitted = (extract == 0)
      Set numeric value: line_number, "omit", omitted


      if word_tier > 0
        Set string value: line_number, "word", word$
        Set numeric value: line_number, "word_interval", wordNum
        Set numeric value: line_number, "word_start", wordStart
        Set numeric value: line_number, "word_end", wordEnd
        Set string value: line_number, "previous_word", previous_word$
        Set string value: line_number, "next_word", next_word$
      endif

      if comment_tier1 > 0
        Set string value: line_number, "comment1", comment1$
      endif
      if comment_tier2 > 0
        Set string value: line_number, "comment2", comment2$
      endif
      if comment_tier3 > 0
        Set string value: line_number, "comment3", comment3$
      endif  
    endif

  endfor

  #appendInfoLine: "output files: ", output_file_count
  .added_number_of_lines =  output_file_count
endproc