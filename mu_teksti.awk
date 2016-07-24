#!/usr/bin/awk -f

#    Uuden musteen muunnin. Converts docx-files to epub-files.
#    Copyright (C) 2016 Matti Palomäki. 
#    Written for www.uusimuste.fi
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

BEGIN {
    OFS = ""
    ORS = ""
    FS = "<[ ]*"
    RS = ">[<]?"
    tiedostonro = 1
    suljettavat = ""
    virheet = ""  
    kirjoitettava = ""
    seuraavana_otsikko = "jep"
    raportointi = 5000; 
}
NR == 1      { kansio = kansio "/OEBPS/"; tiedosto = kansio "1.xhtml"; tiedoston_alkutekstit(tiedosto) }
NR == 1      {
    if (kansikuva) {
	gsub("^(.)*\/", "", kansikuva)              
	while( gsub("^[^\/]*\/", "", kansikuva) ) {   } 
	print "<div class=\"d-cover\" style=\"text-align:center;\">\n<img src=\"" kansikuva "\" alt=\"image\" height=\"100%\"/>\n</div>\n</body>\n</html>" >> tiedosto
	kannen_nimi = substr(kansikuva, 1, length(kansikuva)-4) 
	print "\n" kannen_nimi >> otsikkokansio "otsikot"
	tiedostonro++
	close(tiedosto)
	tiedosto = seuraava_luku_alkaa(tiedosto, tiedostonro, kansio)
    }
}
/body/       { rungossa = "jep!" } 
rungossa == "" {next}  
NR == raportointi {print "\nKäsitelty " NR " riviä."; raportointi += 5000}
/[^ ]\r[^ ]/ { if (seuraavana_otsikko) { gsub(/\r[^ ]/, " &", $1) } }
/\r/         { gsub(/\r/, "<br />", $1) }
/PAGEREF/  {$1 = ""; kirjoitettava = kirjoitettava "      "}
/TOC \\/  {$1 = ""}
/w:instrText/ { $1 = "" }
/wp:align$/ { $1 = "" }
/¤¤¤o¤¤¤/   {
    seuraavana_otsikko = "jep"
    gsub(/¤¤¤o¤¤¤/, "", $0)
    kirjoitettava = kirjoitettava suljettavat "</p>"; suljettavat = ""
    kirjoitettava = hieronta(kirjoitettava, suljettavat)
    if (kirjoitettava ~ "[^ \t\n\r]+") {
	luku_loppuu(tiedosto, suljettavat, kirjoitettava)
	tiedosto = seuraava_luku_alkaa(tiedosto, tiedostonro, kansio)
	tiedostonro++;
        suljettavat=""; kirjoitettava=""
    }
    kirjoitettava = kirjoitettava "<p>"
}
NF>1         { 
    if (seuraavana_otsikko) {
        if (otsikko ~ "[^ ]$" && $1 ~ "^[^ ]") {otsikko = otsikko " "
	}
        otsikko = otsikko "" $1 
    } 
    kirjoitettava = kirjoitettava  $1 "\n"; $0 = $2;
}
/^w:p[ ](.)*\/$/  {kirjoitettava = kirjoitettava "<p><br /></p>"; next}
/:pStyle w:val=\"[Hh]eading( )?1/ || /:pStyle w:val=\"[Oo]tsikko[ 1]?\"/  {
     kirjoitettava = kirjoitettava "</p>"
     seuraavana_otsikko = "jep"
     kirjoitettava = hieronta(kirjoitettava, suljettavat)
     if (kirjoitettava ~ "[^ \n\r\t]+") {
	 tiedostonro++;
	 luku_loppuu(tiedosto, suljettavat, kirjoitettava)
	 suljettavat=""
	 kirjoitettava=""
	 tiedosto = seuraava_luku_alkaa(tiedosto, tiedostonro, kansio)
     }
     kirjoitettava = kirjoitettava "<p class=\"h1\">"
}
/:pStyle w:val=\"Heading( )?2/ || /:pStyle w:val=\"[Oo]tsikko( )?2\"/  {
     kirjoitettava = kirjoitettava "</p><p class=\"h2\">" }
/:pStyle w:val=\"Heading( )?3/ || /:pStyle w:val=\"[Oo]tsikko( )?3\"/  {
     kirjoitettava = kirjoitettava "</p><p class=\"h3\">" }
/:pStyle w:val=\"Heading( )?4/ || /:pStyle w:val=\"[Oo]tsikko( )?4\"/  {
     kirjoitettava = kirjoitettava "</p><p class=\"h4\">" }
/:pStyle w:val=\"Heading( )?5/ || /:pStyle w:val=\"[Oo]tsikko( )?5\"/  {
     kirjoitettava = kirjoitettava "</p><p class=\"h5\">" }
/:pStyle w:val=\"[Tt]yyli( )?2/ || /:pStyle w:val=\"[Ss]tyle2\"/  {
     kirjoitettava = kirjoitettava "</p><p class=\"tyyli2\">" }
/:pStyle w:val=\"[Tt]yyli( )?3/ || /:pStyle w:val=\"[Ss]tyle3\"/  {
     kirjoitettava = kirjoitettava "</p><p class=\"tyyli3\">" }
/:pStyle w:val=\"[Tt]yyli( )?4/ || /:pStyle w:val=\"[Ss]tyle4\"/  {
     kirjoitettava = kirjoitettava "</p><p class=\"tyyli4\">" }
/:pStyle w:val=\"[Tt]yyli( )?5/ || /:pStyle w:val=\"[Ss]tyle5\"/  {
     kirjoitettava = kirjoitettava "</p><p class=\"tyyli5\">" }
/w:br\// {kirjoitettava = kirjoitettava "<br />"}
/w:numId w:val=/  {
    lista++
    kirjoitettava = kirjoitettava " " lista ". "
    if (seuraavana_otsikko) { otsikko = otsikko " " lista ". "}
    }
/^w:p$/ || /^w:p w/   {kirjoitettava = kirjoitettava "<p>"}
/\/w:p$/      {
    kirjoitettava = kirjoitettava suljettavat "</p>"; suljettavat = ""
    if (seuraavana_otsikko) {
        gsub("(\n)+", " ", otsikko)
        otsikko = "\n" otsikko
	if (otsikko ~ /^[ \n\r\t]+$/) {otsikko = otsikko "eI OtSIKKOa muTTA lukuVAihTUU SIlti NYT. Kangas kultainen kumahti."} 
        print otsikko "" >> otsikkokansio "otsikot"
        otsikko = seuraavana_otsikko = ""
    }
}
/w:b\//       {kirjoitettava = kirjoitettava "<b>"
               suljettavat = "</b>" suljettavat}
/w:i\//       {kirjoitettava = kirjoitettava "<i>"
    suljettavat = "</i>" suljettavat}
/w:u(.)*\//       {kirjoitettava = kirjoitettava "<u>"
    suljettavat = "</u>" suljettavat}
/\/w:t/       {kirjoitettava = kirjoitettava suljettavat; suljettavat = ""}
END {
    if (rungossa=="") {virheet = virheet  "Asiakirjalla ei ollut \"<body> ... </body>\"-rakennetta.\n"}
    kirjoitettava = hieronta(kirjoitettava, suljettavat)
    luku_loppuu(tiedosto, suljettavat, kirjoitettava)
    if (virheet) {
        print "\nTiedoston tekstin lukemisessa kohdattiin seuraavat virheet:\n" virheet
    } else {
        print "\nVaihe b) onnistui: tiedoston teksti luettiin ja luotiin " tiedostonro + 0 " otsaketta sisällysluetteloon.\n"
    }
}
 
function tiedoston_alkutekstit(tiedosto) {
    print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\"" > tiedosto
    print "\n\"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">" >> tiedosto
    print  "\n<html xmlns=\"http://www.w3.org/1999/xhtml\">\n<head>\n" >> tiedosto
    print "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\" />\n<title>" tiedostonro  >> tiedosto
    print "</title>\n<link rel=\"stylesheet\" type=\"text/css\" href=\"css/tyylit.css\" />\n</head>" >> tiedosto
    print "\n<body>" >> tiedosto
}
function hieronta(kirjoitettava, suljettavat) {
    kirjoitettava = kirjoitettava "" suljettavat
    gsub(/\n/, "", kirjoitettava)
    gsub(/>[ \s]+</, "><", kirjoitettava)
    gsub(/<p>[ \t\f\n\r\v]*<br \/>[ \t\f\n\r\v]*<\/p>[ \t\f\n\r\v]*<p>/, "<p>\n<br />\n", kirjoitettava)  
    gsub(/<i>(<i>)+/, "<i>", kirjoitettava)
    gsub(/<b>(<b>)+/, "<b>", kirjoitettava)
    gsub(/<\/i>(<\/i>)+/, "</i>", kirjoitettava)
    gsub(/<\/b>(<\/b>)+/, "</b>", kirjoitettava)
    while (gsub(/<b><\/b>/, "", kirjoitettava) || gsub(/<i><\/i>/, "", kirjoitettava)) {   }
    while (gsub(/<\/i><i>/, "", kirjoitettava) || gsub(/<\/b><b>/, "", kirjoitettava)) {   }
    gsub(/>/, ">\n", kirjoitettava)
    gsub(/</, "\n<", kirjoitettava)
    gsub(/h1\">\n/, "h1\">", kirjoitettava)
    gsub(/\n<b>\n/, "<b>", kirjoitettava)
    gsub(/\n<i>\n/, "<i>", kirjoitettava)
    gsub(/\n<\/b>\n/, "</b>", kirjoitettava)
    gsub(/\n<\/i>\n/, "</i>", kirjoitettava)
    gsub(/p></, "p>\n<", kirjoitettava)
    gsub(/><\/p/, ">\n</p", kirjoitettava)
    while (gsub(/<p>[\n]*<\/p>/, "", kirjoitettava)) {   }
    gsub(/>[\n]+</, ">\n<", kirjoitettava)
    gsub(/<p[^h>]*>/, "&\r", kirjoitettava)
    gsub(/class=\"h[1-9]?\"[^\r]+<p/, "& class=\"eka\"", kirjoitettava)
    gsub(/class=\"eka\"[^<>\"]+class=\"/, " class=\"eka", kirjoitettava)
    gsub(/\r/, "", kirjoitettava)
    gsub(/\n[\n]{1, }/, "\n", kirjoitettava)
    return kirjoitettava
}
function luku_loppuu(tiedosto, suljettavat, kirjoitettava) {
    
    print kirjoitettava "</body>\n</html>" >> tiedosto
    close(tiedosto)
}
function seuraava_luku_alkaa(tiedosto, tiedostonro, kansio) {
    tiedosto = kansio tiedostonro ".xhtml"
    tiedoston_alkutekstit(tiedosto)
    return tiedosto
}
