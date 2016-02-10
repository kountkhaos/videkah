#######
videkah
#######
By Karl (kount) 'khaos' Hoskin.
From several years ago to Feb 2016.
#########################################
An IDE for Vim , for perl users.
#########################################
Would have been called Vide, but that name seems to have already been (unsurprisingly) taken, so it got name vide and kah after ME!


What does it do ?
#################

It allows hopefully quick navigation around a complex code base of lots of perl modules, in a various few different ways.


It has the following 'videkah' buffers from where you can do different things:-

filelist
    where filenames can be stored, and quickly navigated to

runlist
    where single line commands can be invoked on the shell

Git-Diff
    where a git diff can be created, and you can navigate from the lines in the diff directly to the file.

perl_stacktrace
    where a perl stack trace can be pasted , and navigated around

perl_static_class_hierarchy
    where a file has its static class (i.e. what is sorta available at compile time using PPI) viewable, and navigatable.

perl_ackgrep
    where an ackgrep command has been run on a list of paths, and the results of which can be quickly navigated to.

config
    where various bits can be configured. like the storage location of all the above files, and whether they are saved by the git-branch-name.

    by-git-branch-name
    ##################
    All of the above files can be stored on a general name that would work in all git branches,
    or a by git branch name. i.e. When you're in a checkout of <my-git-branch> all of the above files
    will be stored by the my-git-branch filename.

    This of course relies on you working in a git repository. If you're not working in a git-repo you can't do this.

    PERL_LIBPATHS
    #############


    PERL_ACKGREP_PATHS
    ##################





Toggling between the various special videkah buffers



Getting Started
---------------

You need to checkout from github.com all this stuff ( assuming you're not reading this in a vim editor on your machine ;) )

There is an install script ./install.me.pl this should do most stuff. please read this before you run it. I'd recommend you trying this in a VM machine at first, so it doesn't mangle any existing vimrc stuff you may have.

videkah uses a few other vim plugins namely :

<list them here>

fugitive

You'll need to install these.


once you have that lot, and assuming all the symlinks under your ~/.vim dir are correct, and your PATH includes the videkah/bin/ dir you'll want to run videkah somewhere.


so make a dir somewhere , cd into it.

The run the command "videkah_generate_config"

this generates a .videkah dir with some sub dirs.

Videkah needs this to work.

You should then be able to type :

videkah

Now if you press

<space>c

quickly you'll get to the .videkah/config  buffer.

( you should be there when you run videkah )


Config buffer
-------------

The important thing here is if you aren't running in a git checkout the settings that say ***_GIT_BRANCH=1 will break .

So if you are NOT running in a git checkout you need to remove the "1" from the end of these settings.

i.e.

:%s/GIT_BRANCH=1/GIT_BRANCH=/g

should do it.


There are some useful navigation features that allow quickly opening perl files via there package name . For these to work you need to make the PERL_LIBPATHS=  point to where they are . These path names are relative to directory where you videkah_generate_config . I think absolute path names work, guess I've got to test that ;)

There are some unimplemented settings in there . videkah is Work-in-progress .

There are also some pretty pointless settings like changing where the filelists, runlists are stored. I have used them, for when I had multiple checkouts of the same git-repo and wanted to have common filelists , runlists etc... ( so I guess they're useful )


So now lets got over some videkah commands.

Please note the vast majority of commands are run in "vim command mode", unless indicated otherwise. i.e. insert or visual mode.


Most of the <space>... commands and the videkah buffers.
--------------------------------------------------------

press :

<space><space>

(reasonably quickly)

you should navigate to the "filelist" buffer.
If you are in a git checkout this will take you to the file

./videkah/filelist/<git-branch-name>

the key <f2> is mapped to a command that will show the current filename at the bottom.
press <f2> and you should see the above.

if you're not in a git checkout this will just default to :

./videkah/filelist/filelist

hence in git checkouts you have a different filelist for different branches .


so in the filelist just go into "insert" mode , type a file name , <esc> , now on the same line press <return>

you should navigate to that file. if it doesn't exist , it will be created.

if you <space><space> again the file will be saved and you'll be back at the filelist.

now just press <space>

you should navigate to the runlist

in here insert something in a line like :

ls

<esc> from insert mode , and press <return> on this line .

the command should run in a shell .


if you press <space> again you should get to the git_diff list. This will be blank.
the git_diff buffer is populated by :


<space>d

where you will be given an option on the "git diff" command you're going to run.

of course you have to "git add" new files for "git diff" to see them. so you could do that in another terminal window
( you could add a line "git add ." into the runlist , and just run that. )

in the git diff you can press return on any line that doesn't have a "-" preceding it. In most cases videkah should navigate to that line.

The exception to this is the :

+++ filename

lines , where you'll be given the option to "git commit" that file.


so moving on from the git_diff buffer press

<space>

and you should get to the perl_stacktrace buffer.

In here you can paste a perl stacktrace and then there are commands to navigate through the stack trace.
I'll leave this for now. ( I don't use that this much these days )

from the perl_stacktrace buffer press

<space>

and you'll be in the perl_static_class_hierarchy , this buffer is filled with lines when you press <return> in a perl file on a line that says :

use base

and there are some "moose-isms" that if you press <return> on the line in the perl file like

with ....

will generate a perl class hierarchy.

The lines in the perl hierarchy , if you press return on them will navigate to the perl file.

next from the perl_static_class_hierarchy file press

<space>

you should now be in the perl_ackgrep file , that I hardly ever use . I need to test this again and make sure its working.

again the lines in here that are generated by an ackgrep command can be navigated to by pressing <return>

from the perl_ackgrep buffer press

<space>

and you should be back at the .videkah/config


Now keep pressing space to cycle through these buffer is painful so :


<space>c    will take you to the config

<space><space>  will take you to the filelist
<space>f        will take you to the filelist

<space>r    will take you to the runlist

<space>d    will take you to the git-diff , and offer to run git-diff. press <esc> if you don't want to git-diff

<space>t    will take you to the stacktrace

<space>h    will take you to the perl class hierarchy buffer

<space>g    will take you to the perl ackgrep buffer


there are some other <space><other-key(s)> commands :

<space>a  will add the current file you're in to the filelist (only if it doesn't exist )


<space>dd  does some jiggery pokery going over a git-diff and finding lines that have been marked #TODO RM this line , and then navigates to another buffer.

<space>dr  does the same as above.


<space>y    generates a line that can be pasted into the filelist for navigation.
            so you go to a file, find a line , press "<space>y" .
            This copies a line into the main register that a regular "p" will paste.
            then navigate to any file, and press "p"

            The line pasted is prefixed with ## .
            This is so it can be pasted into a perl file without breaking compile.
            In a regular perl file you can now press <return> on this line and it videkah should navigate there.
            If you paste this line in the filelist you need to delete the ##.
            ## lines in the filelist are ignored by <return>

<space>u    generates a different type of navigation line that I use in my "todo" list use of perl
            these lines can also be used for navigation. I need to explain this a bit better.


Function keys
-------------
Now for some <f-keys>

<f2>        will give the current file/buffer name.
<f3>        toggles between the last to buffers opened.
<f3><f3>    will give you the buffer list to select from.
<f4>        opens a file, sub name plugin called "taglist" , that you need to install.
            ( need details of the URL where this is )

<f5>        opens NERDTree , another file browser plugin from someone else. (NERD_Tree.vim)
<leader>e   also opens NERDTree. <leader> is "\" key in my videkah vimrc stuff.

<f6>        closes the current file, only if it is saved.
<f7>        is hardcoded in the vimrcs to run something I am working on at present.
            This will probably be made to run the first line of the runlist.
<f8>        saves all files and quits videkah
<f9>        saves the current buffer/file.
<f10>       dunno ! nothing i think.
<f11>       seems to run the current file. need to check this.
<f12>       will look on the current line for http**** and try and open what it thinks is a URL in a browser.



<leader> commands
-----------------

Now for some <leader><key> commands . (where <leader> is "\" )

<leader>#   hashes out the next 3 lines. ( in vim command mode )
            if you have a visual selection of lines then this will hash out the entire visual selection

            Also one of the few non-perl things here , if you do this in a file suffixed ".sql"    then <leader># will prefix with "--" . ".c" and ".js" files will be prefixed with "//" ( although that is a bit wrong for "pure c" )


<leader>c   toggles column width stuff. Between 80 and 8000 characters.
            useful when running over a git-diff before commiting.

<leader>d   gives some insert date options that I use in my vim todo-list files.

<leader>g   runs the fugitive.vim :Gblame command ( you need to install fugitive.vim )

<leader>h   turns on/off syntax highlighting. Some I knew (know?) didn't like syntax highlighting ;)

<leader>m   toggles mouse usage
mm          toggles mouse usage

<leader>n   :set invnumber

<leader>o   :e<cr>    # reopen a file

<leader>s   horizontally splits the screen

<leader>t   switches tab from 4-space to <tab> mode. Useful for makefiles.

<leader>v   vertically splits the screen.


if you've split the screen with <leader>v or <leader>s

<alt><up-cursor>   navigate around panes
<alt><down-cursor> navigate around panes
<alt><left-cursor> navigate around panes
<alt><right-cursor> navigate around panes



iab insert mode shortcuts
-------------------------

there are a lot of insert mode short cuts , have a look in
videkah/bin/vimrc_videkah_iab_debug

A lot of these now seem a bit pointless.

However there are some that are worth a special mention.

some of the "iab" insert debug lines . here's one of them :

" vpd  = videkah perl dumper ( if you already have use Data::Dumper somewhere )
iab vpd <ESC>0iprint STDERR "\nvidekahnum Dumper of   =".Dumper (); # TODO rm this line<cr><ESC>klllllllllllllllllllllllllllllllllllli

The videkahnum can get filename and numbered with the following command :

<space>n

( I used to have to debug some *interesting* code, don't use this much now, I've got better ways ;) )



The "# TODO RM this line"
-------------------------

<leader>r   will append a suffix to a line :
            # TODO RM this line.

            The git-diff  <space>dd  or <space>dr  generates these a buffer where these lines can be seen and removed in bulk . ( before commiting debug crap to the git-repo )



You can visual select  ("v") lines with these "# TODO RM this line" and just strip the # TODO RM this line only with (whilst in visual mode) :

<leader>rr

If you visual select some lines and press :

<leader>r

you will get "# TODO RM this line" appended to all the lines selected.

Yes this is a bit broken . You can end up with lots of "# TODO rm this line" appended to the same line. This needs working on. hmmm.



navigation features in a perl file.
-----------------------------------

in a perl file if you press <return> on a "use" statement, and the videkah config option for PERL_LIBPATHS is set you should navigate to the perl module.

if you are on a ## line , and it looks like a file name , it will try and navigate there.

on a "use base" line , and some of the "moose" directives like "with" it will try and generate a "class hierarchy" buffer, and you can navigate with <return> there .

if you visually select something then <return><return> will do the perl-ackgrep stuff. This seems broken at present. needs fixing.

on a visual select of something and a single <return> will do something different. I need to look at this again . 


perl stack trace stuff.
-----------------------

TODO write about this.



perl ack grep
-------------

TODO write about this.



