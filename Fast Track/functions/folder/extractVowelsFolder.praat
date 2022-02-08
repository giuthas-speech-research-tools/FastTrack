# requires vwlTbl, segment_tier, word_tier

segment_tier = 1
word_tier = 0

tg = selected ("TextGrid")
snd = selected ("Sound")
basename$ = selected$ ("Sound")

include utils/importFunctions.praat
@getSettings

@getTGESettings


form Analyze formant values from labeled segments in files
	comment Directory of sound files
	text sound_directory ../../../vowel_test_set/orig_sounds
	sentence Sound_file_extension .wav
	comment Directory of TextGrid files
	text textGrid_directory ../../../vowel_test_set/orig_sounds
	sentence TextGrid_file_extension .TextGrid
	comment Path of the extracted vowels directory:
	text resultdir ../../../vowel_test_set/extractedVowels

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
endform

@saveTGESettings

maintain_separate = 0
stress = stress_is_marked_on_vowels
output_folder$ = resultdir$

Create Strings as file list: list 'sound_directory$'*'sound_file_extension$'
numberOfFiles = Get number of strings

# Go through all the sound files.
for ifile to numberOfFiles
	filename$ = Get string: ifile

	# A sound file is opened from the listing:
	Read from file: 'sound_directory$''filename$'

	# Open a TextGrid by the same name:
	gridfile$ = "'textGrid_directory$''soundname$''textGrid_file_extension$'"

	if fileReadable (gridfile$)
		Read from file: 'gridfile$'

		@extractVowels

		# Remove the TextGrid object from the object list
		select TextGrid 'soundname$'
		Remove
	endif
	# Remove the Sound object from the object list
	select Sound 'soundname$'
	Remove
	# and go on with the next sound file!
	select Strings list
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
