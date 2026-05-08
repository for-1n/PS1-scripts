<# :
@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
	powershell -Noprofile -Executionpolicy bypass -command "Start-process -filepath '%0' -Verb RunAs"
exit /b
)
powershell -Noprofile -Executionpolicy bypass -command " iex ((Get-content '%~f0' -Raw)) "
#>

function Start-tools {

<# Делаем отдельную функцию для структурированного порядка действий и облегчения рефакторинга

 внутри него бесконечный цикл "do while" очищая перед терминал после каждого вызова комманд

#>	
do {
		clear-host
		$textmenu = @"
			
	
				======================
				1. powershell
				2. compmgmt.msc
				3. regedit
				4. explorer
				5. msinfo32
				6. taskmgr
				7. ncpa.cpl
				8. appwiz.cpl
				9. sysdm.cpl
				0. Back to command
				======================
"@
<# Пишем меню, далее считываем ввод пользователя через переменную;
Далее свитч ставит условия через "", соотвественно считывая ввод пользователя и запускает утилиты указанные в меню -

 - в зависимости от того что какую цифру выберет юзер, дефолт необходим для того чтобы программа знала что делать

если ввод не совпал ни с одним из предложенных вариантов, вместо того чтобы проигнорировать ввод

start-sleep нужен чтобы человек успел увидеть текст при условии default
 
#>
		Write-host $textmenu -foregroundcolor cyan
		$typeTools = Read-Host 
		switch ($typeTools) {
			"1" {start-process powershell.exe}
			"2" {start-process mmc.exe "compmgmt.msc"}
			"3" {start-process regedit}
			"4" {start-process explorer.exe}
			"5" {start-process msinfo32.exe}
			"6" {start-process taskmgr.exe}
			"7" {start-process control.exe "ncpa.cpl"}
			"8" {start-process control.exe "appwiz.cpl"}
			"9" {start-process control.exe "sysdm.cpl"}
			"0" {return}
			default {
			Write-Host "Your input $typeTools isnt exist" -foregroundcolor red
			Write-Host "Type from 0 to 9" -foregroundcolor green
			start-sleep -seconds 1.5
			}
		}
	} while ($true)
}
function PrinterDrivers {
<#
Тут мы уже делаем функцию внутри которой свитч выполняет другую функцию  uninstall-printers
так как большой код должен лежать отдельно от свитч для упрощение просмотра и анализа кода
это будет облегчать нам рефакторинг в будущем и предотвратит количество ошибок и простыню из кода легче будет удерживать
#>

	do {
	
		clear-host
		$textmenu = @"
		
				====================================
				1. See printers
				2. See printers drivers
				3. Remove printer and driver printer
				0. Back
				====================================
"@
		Write-Host $textmenu -foregroundcolor cyan
		$typePrinter = Read-Host 
		switch ($typePrinter) {
			"1" {get-printer | out-host; Read-Host "Type enter to continue" } # Принудительно заставляем показать вывод команды иначе цикл начнется заново
			"2" {get-printerdriver | out-host; Read-Host "Type enter to continue"}
			"3" { uninstall-printers }
			"0" {return} #Делаем возврат из того момент откуда все началось соотвественно у нас это основное меню
			default {
			Write-Host "Your input $typePrinter isnt exist" -foregroundcolor red
			Write-Host "Type from 0 to 3" -foregroundcolor green
			start-sleep -seconds 1.5
			}
		}		
	} While ($true)
}
function uninstall-printers {
<# Тут самая сложная функция, буду обьяснять подробно
В переменную мы обязаны закинуть вывод команды для взаимодействия с обьектами
#>


	$driver = get-printerdriver
	$i = 1	 #делаем переменную для нумерации обьектов по порядку 
	foreach ($c in $driver) { 	#в цикле перебираем сами обьекты и выставляем эту переменную то есть цифру каждому обьекту по порядку
		"$i. $($c.Name)" 	# выводим цифру и имя через свойство Name списком 
		$i ++ 	# прибавляем каждую цифру каждому следующему обьекту 
	}
	$choice = Read-Host "Type number of printer driver"
	
	$index =[int]$choice - 1 #  так как люди считают от 1 а комп от 0 то мы просто вычитаем индекс отнимая одну цифру
							 #  тоесть заставляем перенаправить не на 1 а на 0 но это будет выглядеть как 1 потому что мы начали переменную от единицы

	$first = $driver[$index] 		# кладем в переменную только один драйвер принтера через скобки которые обозначают индекс переменной $index
	
	Write-host "You choice the driver: $($first.Name)"
	Write-host "Remove the printer driver: $($first.Name)"  -foregroundcolor Red
	
	if ($null -ne $first) { 	# делаем условия где $null это ноль тоесть отсутствие , грубо говоря если переменная не равна нулю тогда исполняем код ниже
		
		try {
			$Byeprinter = get-printer | where-object {$_.Drivername -eq $first.name} # начнем с where-object, фильтруем с помощью where-object вывод обьектов get-printer
																		#фильтруем мы через аргумент -equal (eq) для поиска совпадений с переменной где мы положили драйвера 
	
			$Byeprinter | Remove-printer -ErrorAction Stop -Confirm 	#Кидаем переменную в которой лежат отсортированные принтера  в команду для удаления через пайп "|" 
			
			Restart-Service -Name Spooler -ErrorAction Stop -force 		#Перезапускаем службу печати 
																	#чтобы  потом можно было удалить драйвер иначе будет ошибка "Принтер используется"
			
			Start-sleep -seconds 4	
			Remove-printerdriver -Name $first.Name -ErrorAction Stop	# И наконец удаляем драйвера по имени переменной,
																		# а имя переменной будет пронумерованные цифры принтеров 
		}
		catch { #Если буду ошибки ловим через catch и заставляем показать $_ что означает конкретную ошибку
		
				Write-host "Cannot delete because $_" -foregroundcolor red
				start-sleep -seconds 7
		}
	} else { # В случае если  условие if не сработало тоесть написана не та цифра скрипт не валит ошибки а пишет об некоректности
			
			write-host "You write not correct number"
		}

}

<#
####КОД КОТОРЫЙ ВЫПОЛНЯЕТ ОСНОВНЫЙ ДЕЙСТВИЯ####
			|
			|
		   \|/
#>
<# 
	### Делаем главное меню через цикл do while чтобы оно было бесконечным
	###	Пишем переменную для считывания вывода пользователя и по самому выводу мы через условие в switch "" отсылаемся на функцию которая выполняет код основной
	###	Также делает дефолт чтобы не игнорировать неправильный ввод юзера а указать только на существующие варинты и закрываем скобки цикла do while таким образом
	###	завершая весь наш скрипт
#>
do {
clear-host
$ux = @"
		====================
			  Type
		1. to starting tools
		2. to printerdrivers
		3. Quit
		====================
"@
	Write-Host $ux -foregroundcolor cyan
	$userintype = Read-Host 
	switch ($userintype) {
	"1" {Start-tools}
	"2" {PrinterDrivers}
	"3" {exit}
		default {
		Write-Host "Your input $userintype isnt exist" -foregroundcolor red
		Write-Host "Type from 1 to 3 " -foregroundcolor green
		start-sleep -seconds 1.5
		}
	}
} while ($true)