{******************************************************************
*  (c)copyrights Capella Development Group, Donetsk 1999 - 2000
*  Project: Zeos Library
*  Module: Function for string patterns process
*  Author: Sergey Seroukhov   E-Mail: voland@kita.dgtu.donetsk.ua
*  Date: 17/04/99
*
*  List of changes:
*    13/03/00 - Fixed style (Thanks Robert Marquardt)
******************************************************************}

unit Match;
{
  File: match.pas
  Author: Kevin Boylan
  Modifier: Sergey Seroukhov

  This code is meant to allow wildcard pattern matches.
  It is VERY useful for matching filename wildcard patterns.
  It allows unix grep-like pattern comparisons, for instance:

	?	   	Matches any single characer
	*	   	Matches any contiguous characters
	[abc]  	Matches a or b or c at that position
	[^abc]	Matches anything but a or b or c at that position
	[!abc]	Ditto
	[a-e]  	Matches a through e at that position

	'ma?ch.*'	-Would match match.exe, mavch.dat, march.on, etc
	'this [e-n]s a [!zy]est' - Would match 'this is a test',
                               but would not match 'this as a yest'

  This is a Delphi VCL translation from C code that was downloaded from CIS.
  C code was written by J. Kerceval and released to public domain 02/20/1991.
  This code is ofcourse also public domain. I would appreciate it if you would
  let me know if you find any bugs.  I would also appreciate any notes sent my
  way letting me know if you find it useful.
}

interface

uses SysUtils;

{ Check if Text equal to pattern }
function IsMatch(Pattern, Text: string): Boolean;

implementation

const
{ Match defines }
  MATCH_PATTERN	  = 6;
  MATCH_LITERAL	  = 5;
  MATCH_RANGE	  = 4;
  MATCH_ABORT	  = 3;
  MATCH_END	  = 2;
  MATCH_VALID	  = 1;
{ Pattern defines }
  PATTERN_VALID	  =  0;
  PATTERN_ESC	  = -1;
  PATTERN_RANGE	  = -2;
  PATTERN_CLOSE	  = -3;
  PATTERN_EMPTY	  = -4;
{ Character defines }
  MATCH_CHAR_SINGLE	        = '?';
  MATCH_CHAR_KLEENE_CLOSURE     = '*';
  MATCH_CHAR_RANGE_OPEN	        = '[';
  MATCH_CHAR_RANGE	        = '-';
  MATCH_CHAR_RANGE_CLOSE        = ']';
  MATCH_CHAR_CARET_NEGATE       = '^';
  MATCH_CHAR_EXCLAMATION_NEGATE	= '!';

function Matche(Pattern, Text: string): Integer; forward;
function MatchAfterStar(Pattern, Text: string): Integer; forward;
//function IsPattern(Pattern: string): Boolean; forward;

function IsMatch(Pattern, Text: string): Boolean;
begin
  Result := (Matche(Pattern, Text) = 1);
end;

function Matche(Pattern, Text: string): Integer;
var
  RangeStart, RangeEnd, P, T, PLen, TLen: Integer;
  Invert, MemberMatch, Loop: Boolean;
begin
  P := 1;
  T := 1;
  Pattern := LowerCase(pattern);
  Text    := LowerCase(Text);
  PLen    := Length(pattern);
  TLen    := Length(text);
  Result  := 0;
  while ((Result = 0) and (P <= PLen)) do
  begin
    if T > TLen then
    begin
      if (Pattern[P] = MATCH_CHAR_KLEENE_CLOSURE) and (P+1 > PLen) then
        Result := MATCH_VALID
      else
        Result := MATCH_ABORT;
      Exit;
    end else
      case (Pattern[P]) of
        MATCH_CHAR_KLEENE_CLOSURE:
          Result := MatchAfterStar(Copy(Pattern,P,PLen),Copy(Text,T,TLen));
        MATCH_CHAR_RANGE_OPEN:
          begin
            Inc(P);
            Invert := False;
            if (Pattern[P] = MATCH_CHAR_EXCLAMATION_NEGATE) or
              (Pattern[P] = MATCH_CHAR_CARET_NEGATE) then
            begin
              Invert := True;
              Inc(P);
            end;
            if (Pattern[P] = MATCH_CHAR_RANGE_CLOSE) then
            begin
              Result := MATCH_PATTERN;
              Exit;
            end;
            MemberMatch := False;
            Loop := True;
            while (Loop and (Pattern[P] <> MATCH_CHAR_RANGE_CLOSE)) do
            begin
              RangeStart := P;
              RangeEnd := P;
              Inc(P);
              if P > PLen then
              begin
                Result := MATCH_PATTERN;
                Exit;
              end;
              if Pattern[P] = MATCH_CHAR_RANGE then
              begin
                Inc(P);
                RangeEnd := P;
              if (P > PLen) or (Pattern[RangeEnd] = MATCH_CHAR_RANGE_CLOSE) then
              begin
                Result := MATCH_PATTERN;
                Exit;
              end;
              Inc(P);
            end;
            if P > PLen then
            begin
              Result := MATCH_PATTERN;
              Exit;
            end;
            if RangeStart < RangeEnd then
            begin
              if (Text[T] >= Pattern[RangeStart]) and
                (Text[T] <= Pattern[RangeEnd]) then
              begin
                MemberMatch := True;
                Loop := False;
              end;
            end
            else
            begin
              if (Text[T] >= Pattern[RangeEnd]) and
                (Text[T] <= Pattern[RangeStart]) then
              begin
                MemberMatch := True;
                Loop := False;
              end;
            end;
          end;
          if (Invert and MemberMatch) or (not (Invert or MemberMatch)) then
          begin
            Result := MATCH_RANGE;
            Exit;
          end;
          if MemberMatch then
            while (P <= PLen) and (Pattern[P] <> MATCH_CHAR_RANGE_CLOSE) do
              Inc(P);
            if P > PLen then
            begin
              Result := MATCH_PATTERN;
              Exit;
            end;
          end;
        else
          if Pattern[P] <> MATCH_CHAR_SINGLE then
            if Pattern[P] <> Text[T] then
              Result := MATCH_LITERAL;
      end;
    Inc(P);
    Inc(T);
  end;
  if Result = 0 then
    if T <= TLen then
      Result := MATCH_END
    else
      Result := MATCH_VALID;
end;

function MatchAfterStar(Pattern, Text: string): Integer;
var
  P, T, PLen, TLen: Integer;
begin
  Result := 0;
  P := 1;
  T := 1;
  PLen := Length(Pattern);
  TLen := Length(Text);
  if (PLen = 0) or (TLen = 0) then
  begin
    Result := 3;
    Exit;
  end;
  while ((T <= TLen) and (P < PLen)) and (Pattern[P] = MATCH_CHAR_SINGLE) or
    (Pattern[P] = MATCH_CHAR_KLEENE_CLOSURE) do
  begin
    if Pattern[P] = MATCH_CHAR_SINGLE then Inc(T);
    Inc(P);
  end;
  if T > TLen then
  begin
    Result := MATCH_ABORT;
    Exit;
  end;
  if P > PLen then
  begin
    Result := MATCH_VALID;
    Exit;
  end;
  repeat
    if (Pattern[P] = Text[T]) or (Pattern[P] = MATCH_CHAR_RANGE_OPEN) then
    begin
      Pattern := Copy(Pattern, P, PLen);
      Text    := Copy(Text, T, TLen);
      PLen    := Length(Pattern);
      TLen    := Length(Text);
      p := 1;
      t := 1;
      Result  := Matche(Pattern, Text);
    end;
    if T > TLen then
    begin
      Result := MATCH_ABORT;
      Exit;
    end;
    Inc(T);
  until Result <> 0;
end;

(*
function IsPattern(Pattern: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to Length(Pattern) do
    if Pos(Pattern[I], '[]?*') > 0 then
    begin
      Result := True;
      Exit;
    end;
end;
*)

end.


