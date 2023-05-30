Unit Search;

// Class for handling advanced search operations

Interface Uses Classes, SysUtils;

Type

   TFileSearch = Class
    Private
      Subdir : Boolean;
      Attributes : LongInt;
      FilterList,
      Res : TStringList;
      Dir : AnsiString;
      Function GetFlag(Index : LongInt) : Boolean;
      Procedure SetFlag(Index : LongInt; Value : Boolean);
      Procedure SetPath(s : AnsiString);
      Function GetPath : AnsiString;
      Procedure SetFilterList(s : AnsiString);
      Function GetFilterList : AnsiString;
      Function GetResult(I : Integer) : AnsiString;
      Function GetCount : Integer;
      Procedure DoSearch(d, s : AnsiString);
    Public
      Constructor Create;
      Destructor Destroy; Override;
      Procedure AddFilter(s : AnsiString);
      Procedure Search;
      Procedure ClearFilters;
      Property SearchSubdirectories : Boolean Read Subdir Write Subdir;
      Property Path : AnsiString Read GetPath Write SetPath;
      Property Filters : AnsiString Read GetFilterList Write SetFilterList;
      Property Results[I : Integer] : AnsiString Read GetResult; Default;
      Property Count : Integer Read GetCount;
      Property ReadOnly : Boolean Index faReadOnly Read GetFlag Write SetFlag;
      Property Hidden : Boolean Index faHidden Read GetFlag Write SetFlag;
      Property Archive : Boolean Index faArchive Read GetFlag Write SetFlag;
      Property System : Boolean Index faSysFile Read GetFlag Write SetFlag;
      Property Directory : Boolean Index faDirectory Read GetFlag Write SetFlag;
      Property StringList : TStringList Read Res;
    End;

const
  {$ifdef MSWindows}
     SSLASH = '\';
  {$endif}
   {$ifdef Unix}
     SSLASH = '/';
  {$endif}

Implementation

Constructor TFileSearch.Create;
Begin;
   Attributes := faArchive;
   FilterList := TStringList.Create;
   FilterList.Duplicates := dupIgnore;
   Res := TStringList.Create;
   SearchSubdirectories := False;
   Dir := '.'+SSLASH;

End;

Destructor TFileSearch.Destroy;
Begin;
   FilterList.Free;
   Res.Free;
   Inherited;
End;

Procedure TFileSearch.SetPath(s : AnsiString);
Begin;
   If s[Length(s)] <> SSLASH Then s := s + SSLASH;
   Dir := s;
End;

Function TFileSearch.GetPath : AnsiString;
Begin;
   Result := Dir;
End;

Procedure TFileSearch.AddFilter(s : AnsiString);
Begin;
   FilterList.Add(s);
End;

Function TFileSearch.GetFlag(Index : LongInt) : Boolean;
Begin
   Result := Boolean(Attributes AND Index);
End;

Procedure TFileSearch.SetFlag(Index : LongInt; Value : Boolean);
Begin
   Case Value Of
      True : Attributes := Attributes OR Index;
      False: Attributes := Attributes AND NOT Index;
   End;
End;

Procedure TFileSearch.SetFilterList(s : AnsiString);
Begin;
   While Pos(';',s) > 0 Do s[Pos(';',s)] := ',';
   FilterList.CommaText := s;
End;

Function TFileSearch.GetFilterList : AnsiString;
Begin;
   Result := FilterList.CommaText;
End;

Function TFileSearch.GetCount : Integer;
Begin;
   Result := Res.Count;
End;

Function TFileSearch.GetResult(I : Integer) : String;
Begin;
   Result := Res[I];
End;

Procedure TFileSearch.DoSearch(d, s : AnsiString);
// Search the directory specified by 'd' for filter s.  If
// SearchSubdirectories is set and a directory item is found, then that
// directory is searched recursively.
Var
   Item : TSearchRec;
   Att : LongInt;
   SearchRes : LongInt;
Begin;
   Att := Attributes;
   If SearchSubdirectories Then Begin;
      SearchRes := FindFirst(d + '*.*',faDirectory,Item);
      While SearchRes = 0 Do Begin;
         If (Item.Attr And faDirectory > 0) And (Item.Name[1] <> '.') Then DoSearch(d + Item.Name + SSLASH, s);
         SearchRes := FindNext(Item);
      End;
      FindClose(Item);
   End;
   SearchRes := FindFirst(d + s, Att, Item);
   While SearchRes = 0 Do Begin;
      If Item.Name[1] <> '.' Then Res.Add(d + Item.Name);
      SearchRes := FindNext(Item);
   End;
   FindClose(Item);
End;

Procedure TFileSearch.ClearFilters;
Begin;
   FilterList.Clear;
End;

Procedure TFileSearch.Search;
// Go through each of the filters and search for them.  Return all files
// located in the 'Res' TStringList, which is then accessed by the results
// property or the StringList property.
Var
   w : LongInt;
Begin;
   If FilterList.Count = 0 Then Filters := '*.*';
   Res.Clear;
   For w := 0 To FilterList.Count - 1 Do DoSearch(Dir, FilterList[w]);
End;

End.
