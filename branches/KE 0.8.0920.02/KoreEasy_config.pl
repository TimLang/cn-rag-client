#KoreEasy Main Module - Version: 0.8.00

#KoreEasy Full Version
our $KoreEasy_version = "KoreEasy";
require 'KoreEasy_parseFiles.pl';
require 'KoreEasy_parseInput.pl';
require 'KoreEasy_parseMessage.pl';
require 'KoreEasy_sendMessage.pl';
require 'KoreEasy_AI.pl';
require 'KoreEasy_AIFunctions.pl';
require 'KoreEasy_functions.pl';
require 'KoreEasy_addon.pl';
require 'KoreEasy_auth.pl';

our $main_version = "0.8.0920.02";

#our $beta_version = "MVP SYSTEM";
#require 'KoreEasy_mvp_1.pl';

our $beta_version = "Open Beta";
require 'KoreEasy_mvp_0.pl';


initMVPvar();

sub printLogo {
        my $logo_version = ' ' x int((28-length($KoreEasy_version.$main_version))/2) . "�� $KoreEasy_version $main_version ��";
        my $logo_beta = ' ' x (16 - length($beta_version)) . $beta_version;
        print "\n";
        printc("w" , "                                                             $logo_beta\n");
        printc("w" , "        �x�y�{�z�y�x�x\n");
        printc("w" , "        ����������������                                  ��        ��\n");
        printc("w" , "            ��������������                                ��      ����\n");
        printc("w" , "              ��        ��                                ��    ����\n");
        printc("c", "              ���x�y�z����                                ��  ����\n");
        printc("c", "        �y�|�}����������                              ��񨂨���\n");
        printc("c", "              ������  ����������������������������������������\n");
        printc("b", "              ��  �������z����  �{���������z�����z����  ������\n");
        printc("b", "              ��    ����  ����������������  ��������������������\n");
        printc("b", "              ��     �x�x�x�x�x�x�x�x�x�x�x�x�x�x�x�x�x�x ��  ����\n");
        printc("bwb", "              ��               ", "RAGNAROK ONLINE", "            ��    ����\n");
        printc("b", "              ��     ������������������������������������ ��      ����\n");
        printc("y" , "                      $logo_version\n\n");
        printc("w" , "            ԭ��: Kura    �޶�: ICE-WR    ��վ: http://www.mu20.com\n\n");
        printc("g", "  �ر��л: Karasu  RORO  szboy  Alice  Rensoft  4xyz  w_b_b_w  modKore  KoreC\n\n\n");

        sleep(2);
}


1;