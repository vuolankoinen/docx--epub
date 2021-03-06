#!/usr/bin/awk -f

#    Uuden musteen muunnin. Converts docx-files to epub-files. Written for www.uusimuste.fi
#    Copyright (C) 2016 Matti Palomäki
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

BEGIN {RS=">"}
/Target=\"[^\"]+\.png"/ { 
    kuvatiedosto = kaiva_merkkijono($0, "Target")
    gsub("(.)*/","",kuvatiedosto)
    kuvan_id = kaiva_merkkijono($0, "Id")
    system("mv " kansio "" kuvatiedosto " " kansio "" kuvan_id ".png")
}
function kaiva_merkkijono( rivi, muuttuja ){
    match(rivi, muuttuja "=\"[^\"]+\"")
    arvo = substr( rivi, RSTART +2 +length(muuttuja), RLENGTH -3 -length(muuttuja) )
    return(arvo)
}
