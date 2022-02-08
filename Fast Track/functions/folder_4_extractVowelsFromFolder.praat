# requires vwlTbl, segment_tier, word_tier

segment_tier = 1
word_tier = 0

sound_directory$ = "../../../vowel_test_set/orig_sounds"
sound_file_extension$ = ".wav"
textGrid_directory$ = "../../../vowel_test_set/orig_sounds"
textGrid_file_extension$ = ".TextGrid"
resultdir$ = "../../../vowel_test_set/extractedVowels"

include utils/importFunctions.praat
@getSettings

@getTGESettings


beginPause: "Extract vowels from sound files in folder"
	comment: "Directory of sound files"
	sentence: "../../../vowel_test_set/orig_sounds", sound_directory$
	sentence: ".wav", sound_file_extension$
	comment: "Directory of TextGrid files"
	sentence: "../../../vowel_test_set/orig_sounds", textGrid_directory$
	sentence: ".TextGrid", textGrid_file_extension$
	comment: "Path of the extracted vowels directory:"
	sentence: "../../../vowel_test_set/extractedVowels", resultdir$

	comment: "Which tier contains segment information?"
	positive: "Segment tier:", segment_tier
	comment: "Which tier contains word information? (not necessary)"
		integer: "Word tier:", word_tier
	comment: "Optional tiers (up to 3) containing comments that will also be collected."
		integer: "Comment tier1:", 0
		integer: "Comment tier2:", 0
		integer: "Comment tier3:", 0
	comment: "If anything is written in this tier, the segment will be skipped:"
		integer: "Omit tier:", 0
	boolean: "Stress is marked on vowels", stress
	sentence: "Stress to extract", stress_to_extract$
	sentence: "Words to skip:", "--"
	boolean: "Save segmentation information:", 1
	boolean: "Save file information:", 1
	positive: "Buffer (s):", 0.025
nocheck endPause: "Ok", 1

@saveTGESettings

maintain_separate = 0
stress = stress_is_marked_on_vowels
output_folder$ = resultdir$

glob$ = "/*" + sound_file_extension$
Create Strings as file list: "list", sound_directory$ + glob$ 
numberOfFiles = Get number of strings

################################################################################################
###### This handles stress extraction

stress_override = 0

if stress_to_extract$ <> ""
  tmp_strs = Create Strings as tokens: stress_to_extract$, " ,"
  stresses = To WordList
  removeObject: tmp_strs
  stress_override = 1
endif

if fileReadable ("../dat/stresstoextract.txt") and stress_override == 0 and stress = 1
  tmp_strs = Read Strings from raw text file: "../dat/stresstoextract.txt"
  stresses = To WordList
  removeObject: tmp_strs
endif 


##############################################################################################
###### Here I get the information about which vowels to extract

extract_file = 0

if fileReadable (folder$ + "/vowelstoextract.csv")
  vwl_tbl = Read Table from comma-separated file: folder$ + "/vowelstoextract.csv"
  extract_file = 1
endif 

if fileReadable ("../dat/vowelstoextract.csv") and extract_file = 0
  vwl_tbl = Read Table from comma-separated file: "../dat/vowelstoextract.csv"
  extract_file = 1
endif 
if !fileReadable ("../dat/vowelstoextract.csv") and extract_file = 0
   if !fileReadable ("../dat/vowelstoextract_default.csv")
     exitScript: "You do not have either an vowelstoextract_default.csv nor a vowelstoextract.csv file in your /dat/ folder. Please fix and run again!!"
   endif
  vwl_tbl = Read Table from comma-separated file: "../dat/vowelstoextract_default.csv"
endif 

Rename: "vowels"


################################################################################################
###### This section adds group and color information to vowel tables if the user has not provided it

selectObject: vwl_tbl
fill_group = Get column index: "group"
fill_color = Get column index: "color"
nrows = Get number of rows

if fill_group == 0
  Append column: "group"
endif

if fill_color == 0
  Append column: "color"
  .clr_str = Create Strings as tokens: "Red Blue Black Green Olive Yellow Magenta Black Lime Purple Teal Navy Pink Maroon Grey Silver Cyan Black", " ,"
endif

for .tmpi from 1 to nrows
  if fill_group == 0
    selectObject: vwl_tbl
    Set numeric value: .tmpi, "group", .tmpi
  endif
  if fill_color == 0
    selectObject: .clr_str
     color_use = (.tmpi mod (18)) + 1
    .tmp_clr = Get string: .tmpi
    selectObject: vwl_tbl
    Set string value: .tmpi, "color", "Blue"
  endif  
endfor

nocheck removeObject: .clr_str

#################################################################################################

words_to_skip = 0
## make table with words to skip
if words_to_skip$ <> "--"
  words_to_skip = 1
  .skipWords = Create Strings as tokens: words_to_skip$, " ,"
endif

if fileReadable ("../dat/wordstoskip.txt")
  words_to_skip = 1
  .skipWords = Read Strings from raw text file: "../dat/wordstoskip.txt"
endif

if fileReadable (folder$ + "/wordstoskip.txt")
  words_to_skip = 1
  .skipWords = Read Strings from raw text file: folder$ + "/wordstoskip.txt"
endif

if words_to_skip == 1
  Rename: "wordstoskip"
  n = Get number of strings

  wordTbl = Create Table with column names: "wordstoskip", n, "word"
  for i from 1 to n
    selectObject: "Strings wordstoskip"
    tmp$ = Get string: i
    selectObject: "Table wordstoskip"
    Set string value: i, "word", tmp$
  endfor
  removeObject: "Strings wordstoskip"  
endif

#################################################################################################

  ## make table that will contain all output information
    tbl = Create Table with column names: "table", 0, "inputfile outputfile vowel interval duration start end previous_sound next_sound omit"
    if stress == 1
      Append column: "stress"
    endif
    if word_tier > 0
    Append column: "word"
    Append column: "word_interval"
    Append column: "word_start"
    Append column: "word_end"
    Append column: "previous_word"
    Append column: "next_word"
    endif
    if comment_tier1 > 0
      Append column: "comment1"
    endif
    if comment_tier2 > 0
      Append column: "comment2"
    endif
    if comment_tier3 > 0
      Append column: "comment3"
    endif

    file_info = Create Table with column names: "fileinfo", 0, "number file label group color"


####################################################################################################################################################################
####################################################################################################################################################################

createDirectory: output_folder$ + "/sounds"

selectObject: "Strings list"
# Go through all the sound files.
for ifile to numberOfFiles
	filename$ = Get string: ifile

	# Open a sound file and select it:
	Read from file: sound_directory$ + "/" + filename$
	soundname$ = selected$ ("Sound", 1)

	# Open a TextGrid by the same name:
	gridfile$ = textGrid_directory$ + "/" + soundname$ + textGrid_file_extension$

	if fileReadable (gridfile$)
		Read from file: gridfile$
		selectObject: "TextGrid " + soundname$
		plusObject: "Sound " + soundname$
		tg = selected ("TextGrid")
		snd = selected ("Sound")
		basename$ = selected$ ("Sound")

		@extractVowels

		# Remove the TextGrid object from the object list
		selectObject: "TextGrid " + soundname$
		Remove
	endif
	# Remove the Sound object from the object list
	selectObject: "Sound " + soundname$
	Remove
	# and go on with the next sound file!
	selectObject: "Strings list"
endfor


#-------------
# This procedure finds the number of a tier that has a given label.

procedure GetTier name$ variable$
        numberOfTiers = Get number of tiers
        itier = 1
        repeat
                tier$ = Get tier name... itier
                itier = itier + 1
        until tier$ = name$ or itier > numberOfTiers
        if tier$ <> name$
                'variable$' = 0
        else
                'variable$' = itier - 1
        endif

	if 'variable$' = 0
		exit The tier called 'name$' is missing from the file 'soundname$'!
	endif

endproc
