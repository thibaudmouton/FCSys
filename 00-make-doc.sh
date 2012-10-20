#!/bin/bash
# Process the help files and upload a version to github pages
# (http://kdavies4.github.com/FCSys/).

# Original working branch
branch=`git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3`

# Remove some of the help files.
rm help/FCSSys.Blocks*
rm help/FCSSys_Blocks*
rm help/*Figures*.html
rm help/FCSSys.Systems*
rm help/FCSSys_Systems*
rm help/*WorkInProgress*

# Clean up the help files (for local browsing as well as web).
./00-process-help.py

## Update the Github web pages.
git commit -am "Before auto-clean documentation"
git checkout gh-pages
git checkout $branch 00-process-gh-pages.py

# Update the style sheet.
git checkout $branch resources/www/modelicaDoc.css
cp -f resources/www/modelicaDoc.css stylesheets

# Update the images.
rm images/*
cp help/*png images/
for f in `find ./resources/images -iname *.png -o -iname *.svg -o -iname *.ico -o -iname *.gif`
do
    cp $f images/
done

# Copy and process the HTML files.
cp help/*.html ./
mv -f FCSys.html index.html
./00-process-gh-pages.py

# Be sure that all of the files are added to git.
#git add images
#for f in *.html
#do
#    git add $f
#done

# Update the Github web pages and return to the original branch.
git commit -am "Auto-update github pages"
#git push origin gh-pages
git checkout $branch

# Clean up.
rm *.html
