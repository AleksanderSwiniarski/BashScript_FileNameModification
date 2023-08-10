# BashScript_FileNameModification

Simple bash script dedicated for modifying file names. It can lowerize, uppercase or change them accordingly to the specified sed pattern. Changes may be done with recrusion or not. Additionally it changes the file names of files in the hidden directories.

Script allows for following syntax:

  modify [-r] [-l|-u] <dir/file names...>
  modify [-r] <sed pattern> <dir/file names...>
  modify [-h]
