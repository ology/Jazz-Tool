# Jazz::Tool

Blues-Jazz (Jazz-Blues?) Improv Practice Tool

This is a 12-bar oriented practice tool. That is, it's made to play groups of 12 bars, in the standard ("simple") `I7 I7 I7 I7 / IV7 IV7 I7 I7 / V7 V7 I7 I7` progression. So 24 or 36, etc. measures make more sense than any other multiple. However, Jazz is freeform by nature. So YMMV.

The detailed write-up for the code behind this app is [this link](https://ology.github.io/2022/11/25/twelve-bar-jazz-practice/).

To install, have [Perl](https://www.perl.org/) and [cpanm](https://foswiki.org/Support/HowToInstallCpanModules#Install_CPAN_modules_into_your_local_Perl_library_using_61App::cpanminus_61), then:

    git clone https://github.com/ology/Jazz-Tool.git
    cd Jazz-Tool
    cpanm --installdeps .
    morbo jazztool.pl

Then browse to http://localhost:3000/ - Voila!

![](Jazz-Tool-UI.png)
