#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################

ConvertFrom-StringData @'
###PSLOC
Copy_ItemWithStructure_Directory_DirectoryPath = Directory '{0}'.
Copy_ItemWithStructure_File_FilePath = File '{0}'.
Copy_ItemWithStructure_Remove = Remove
Copy_ItemWithStructure_Create = Create
Copy_ItemWithStructure_CopyWithReplace = Copy with possible replace.
Signing_FilePath = Signing '{0}'...
ErrorSigning_Path_Message = Error signing file: '{0}'. Message: '{1}'
Resource_PSObject = PSObject
Operation_New = New
Resource_AuthenticodeSignature_FilePath = Authenticode signature on file: '{0}'
Operation_Set = Set
###PSLOC
'@
