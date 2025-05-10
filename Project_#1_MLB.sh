#!/bin/bash

# Who am i ?
echo "
**********OSS - Project1**********
*       StudentID: 12211162      *
*       Name: Jin Kim            *
**********************************
"

# 팀 이름 목록
teams=(
  "ARI" "ATL" "BAL" "BOS"
  "CHC" "CHW" "CIN" "CLE"
  "COL" "DET" "HOU" "KCR"
  "LAA" "LAD" "MIA" "MIL"
  "MIN" "NYM" "NYY" "OAK"
  "PHI" "PIT" "SDP" "SEA"
  "SFG" "STL" "TBR" "TEX"
  "TOR" "WSN"
)

while true # 무한반복
do

# 메뉴 출력
echo "
[MENU]
1. Search player stats by name in MLB data
2. List top 5 players by SLG value
3. Analyze the team stats - average age and total home runs
4. Compare players in different age groups
5. Search the players who meet specific statistical conditions
6. Generate a performance report (formatted data)
7. Quit"

read -p "Enter your COMMAND (1~7): " var;

# Case 문으로 해당 기능 제공
case $var in

################ 1번 기능 => 선수 입력 받고 세부 지표 출력 (!! NR > 1 : 필드 라인 예외처리 !!) 
"1") 
read -p "Enter a player name to search: " P_name
echo "
Player stats for \"$P_name\":" 
cat 2024_MLB_Player_Stats.csv | awk -F',' -v name="$P_name" '
NR > 1 && $2 == name { 
found = 1
printf("Player: %s, Team: %s, Age: %d, WAR: %.1f, HR: %d, BA: %.3f \n", $2,$4,$3,$6,$14,$20)} 

END {
if (found != 1) {
print("Error: Unknown Player Name !! ") 
}
}
';; 

################ 2번 기능 => SLG 기준 상위 5명 + PA 502 이하는 제외.
"2") 
read -p "Do you want to see the top 5 players by SLG? (y/n): " answer
if [ "$answer" = "y" ]; 
then echo "
***Top 5 Players by SLG***"
# head => 5개에서 짜르기.
# + Except for players less than 502 PA 해야함.
rank=1
awk -F, '$8>502' 2024_MLB_Player_Stats.csv | sort -t, -k 22 -nr | head -n 5 | awk -F, -v rank=$rank '
{printf("%d. %s (Team: %s) - SLG: %.3f, HR: %d, RBI: %d \n",rank,$2,$4,$22,$14,$15)}{rank++}'

else echo "
Return to MENU"
fi
;;

################ 3번 기능 => 팀 명칭 입력 받고, 해당 팀의 종합 통계 출력
"3")
read -p "Enter team abbreviation (e.g., NYY, LAD, BOS): " team_name


found=0


# 해당 팀이 팀 리스트에 있다면 => 해당 팀 분석 출력
for i in "${teams[@]}"; # 팀 이름 배열 요소 for 문으로 추출
do 
if [ "$i" = "$team_name" ];
then 
found=1
echo "
Team stats for $i:"

# 집계 저장용 변수들
average_age=0
total_HR=0
total_RBI=0

# grep으로 해당 팀 선수 목록만 awk로 전달
grep ",$i" 2024_MLB_Player_Stats.csv | 
awk -F, -v i=$i -v average_age=$average_age -v total_HR=$total_HR -v total_RBI=$total_RBI '
{average_age+=$3}{total_HR+=$14}{total_RBI+=$15}
 END {printf("Average age: %.1f \nTotal home runs: %d \nTotal RBI: %d \n",(average_age/NR),total_HR,total_RBI )}' 
break
fi
done

# 팀 리스트에 해당 팀 없을 경우 => 에러
if [ $found -eq 0 ]; # 고쳐야힘
then
echo "
Error: Unknown Team !!
Return To MENU"
fi
;;

################ 4번 기능 => 선수를 연령대 그룹으로 나눔 => 각 그룹 SLG 기준 상위 5명 선수+세부지표 출력
# 추가 조건. PA 502 미만 배제
"4")
# age group 고르는 안내문 
echo "
Compare players by age groups: 
1. Group A (Age < 25)
2. Group B (Age 25-30)
3. Group C (Age > 30)"
read -p "Select age group (1-3): " age_group

# Case 문 => 해당 그룹 출력
case "$age_group" in
1)
echo "
TOP 5 by SLG in Group A (Age < 25):"
awk -F, '$8>502 && $3<25' 2024_MLB_Player_Stats.csv | sort -t, -k 22 -nr | head -n 5 | awk -F, '
{printf("%s (%s) - Age: %d, SLG: %.3f, BA: %.3f, HR: %d\n", $2, $4, $3, $22, $20, $14)}'
;;

2)
echo "
TOP 5 by SLG in Group B (Age 25-30):"
awk -F, '$8>502 && $3>=25 && $3<=30' 2024_MLB_Player_Stats.csv | sort -t, -k 22 -nr | head -n 5 | awk -F, '
{printf("%s (%s) - Age: %d, SLG: %.3f, BA: %.3f, HR: %d\n", $2, $4, $3, $22, $20, $14)}'
;;

3)
echo "
TOP 5 by SLG in Group C (Age > 30):"
awk -F, '$8>502 && $3>30' 2024_MLB_Player_Stats.csv | sort -t, -k 22 -nr | head -n 5 | awk -F, '
{printf("%s (%s) - Age: %d, SLG: %.3f, BA: %.3f, HR: %d\n", $2, $4, $3, $22, $20, $14)}'
;;

*)
echo "
Error: Wrong Age_Group !!
Return to MENU"
;;
esac
;;

################ 5번 기능 => 최소 홈런수 + 최소 타율 입력 => 해당 조건 만족하는 모든 선수들 출력 
# 추가조건. PA 502 미만 배제 + 홈런수 기준 내림차순
"5")

# 최소 홈런수 + 최소 타율 => 입력 받기
echo "
Find players with specific criteria"

read -p "Minimum home runs: " min_HR
# 유효성 검사 => 0 이상의 정수인지
if ! [[ "$min_HR" =~ ^[0-9]+$ ]]; then
echo "
Error: Home runs must be a non-negative integer !!
Return To MENU"
continue
fi

read -p "Minimum batting average (e.g., 0.280): " min_BA
# 유효성 검사 => 0.000 형태의 실수가 맞는지
if ! [[ "$min_BA" =~ ^0\.[0-9]{3}$ ]]; then
echo "
Error: Batting average must be in the form 0.000 (e.g., 0.280) !!
Return To MENU" 
continue
fi

# 해당 조건 만족하는 모든 선수들 출력
echo "
Players with HR ≥ $min_HR and BA ≥ $min_BA:" # NR > 1 => 첫째줄 제외
awk -F, -v min_HR=$min_HR -v min_BA=$min_BA '$8>502 && $14>=min_HR && $20>=min_BA && NR>1' 2024_MLB_Player_Stats.csv | sort -t, -k 14 -nr | awk -F, '
{printf("%s (%s) - HR: %d, BA: %.3f, RBI: %d, SLG: %.3f \n", $2, $4, $14, $20, $15, $22)}'
;;


################ 6번 기능 => 팀 약자 입력 => 해당 팀 보고서 출력
"6")
# 팀 입력 받음
echo "Generate a formatted player report for which team?"
read -p "Enter team abbreviation (e.g., NYY, LAD, BOS): " team_name2

found2=0
# 입력 받은 팀 이름 유효성 검사
for i in "${teams[@]}"; # 팀 이름 배열 요소 for 문으로 추출
do 
if [ "$i" = "$team_name2" ];
then 
found2=1

# 유효성 검사 통과시 
# 해당 팀 보고서 출력 출력
echo "
=================== $team_name2 PLAYER REPORT ===================
Date: $(date +%Y/%m/%d)
---------------------------------------------------------
PLAYER               HR   RBI     AVG      OBP     OPS
---------------------------------------------------------"

# grep으로 해당 팀 선수 목록만 awk로 전달
grep ",$i" 2024_MLB_Player_Stats.csv | sort -t, -k 22 -nr | awk -F, -v i=$i ' 
{printf("%-17s %5s %5s %8s %8s %8s\n",$2,$14,$15,$20,$21,$23)} 
END {printf("---------------------------------------------------------\nTEAM TOTALS: %d players", (NR))}' 
break
fi
done

# 팀 리스트에 해당 팀 없을 경우 => 에러
if [ $found2 -eq 0 ]; # 고쳐야힘
then
echo "
Error: Unknown Team !!
Return To MENU"
fi
;;


######################## 7번째 기능 완성 quit => 프로그램 종료
"7") 
echo "Have a good day!"
break;; 


######################## 메뉴에서 커맨드 잘못 입력시 에러 발생 => 메뉴로 리턴 
*) 
echo "
Error: Wrong COMMAND !!";;
esac

done