function aa($str)
{
    if(preg_match_all("/(........)(........)(........)(........)/",$str,$arr,PREG_PATTERN_ORDER))
    {
        $k='';
        var_dump($arr[1][0]);
        $k.=substr(("RSK".strtoupper(implode("",array_reverse(preg_split("/(..)/",$arr[1][0],-1,PREG_SPLIT_DELIM_CAPTURE))))),0,8);
        $k.=substr(("ZXJ".strtoupper(implode("",array_reverse(preg_split("/(..)/",$arr[2][0],-1,PREG_SPLIT_DELIM_CAPTURE))))),0,8);
        $k.=substr(("RTY".strtoupper(implode("",array_reverse(preg_split("/(..)/",$arr[3][0],-1,PREG_SPLIT_DELIM_CAPTURE))))),0,8);
        $k.=substr(("666".strtoupper(implode("",array_reverse(preg_split("/(..)/",$arr[4][0],-1,PREG_SPLIT_DELIM_CAPTURE))))),0,8);
        echo $k."<br />";
        return strtoupper(md5($k));
    }
    return "";
}

echo aa($_GET["a"]);