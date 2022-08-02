function strUpd = replaceCharacter(strIn,charFind,charReplace)

idx = strfind(strIn,charFind);
strUpd = strIn;
strUpd(idx)=charReplace;