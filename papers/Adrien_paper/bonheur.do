/***** Zones G�ographiques ou PIB/habitant (PPP) : 
    Qu'est-ce qui pr�dit le mieux le bonheur d'un pays ? *****/

/* Cr�ation du fichier bonheur.dta (partie technique et peu importante) */

// Utilisation des donn�es du World Values Survey, nettoyage des donn�es avec bonheurLayard.do
// Les variables inutiles ont �t� �vacu�es, et les indicateurs de bonheur des pays cr��es
// Les valeurs du PIB/habitant PPP ($ constants 2011) ont �t� ajout�es � la main dans la variable Y
// Les valeurs retenues pour Y correspondent � la date de la derni�re vague d'enqu�te de chaque pays
// Ainsi, on �vacue les donn�es des vagues d'enqu�te ant�rieures
//     drop if s002 != derniereVague
//     duplicates drop s003, force
// Les indicatrices de 6 Zones G�ographiques sont cr��es : Afrique (11 pays), AmeriqueLatine (11), MoyenOrient (7 dont �gypte), Occident (14 dont Australie et Nouvelle-Z�lande), Asie (13), EuropeDelEst (dont Russie et pays du Caucase)
cd "\\VBOXSVR\Google_Drive\Economie\Travail\Well-being\"
use "bonheur.dta", clear

/* R�ponse � la question */

// Pour chaque indicateur de bonheur, on �value la part de la variance expliqu�e par la zone g�ographique : r^2_ZG
//   ainsi que la part de la variance expliqu�e par le PIB/habitant (PPP) : r^2_Y
// Le signe de la diff�rence des deux permet de savoir ce qui pr�dit le mieux l'indicateur, entre la zone g�ographique et le PIB/hab
// On calcule �galement le F-test qui a pour hypoth�se nulle que Y est ind�pendant lin�airement de l'indicateur, quand on contr�le pour la zone g�ographique

global affiche 1
foreach bonheur in tresHeureux heureux tresMalheureux ratioHappy satisfaits6a10 satisfaction bonheur bonheurLayard {
	if ($affiche) {
		display "           r^2 ZG | p-value du F-test | r^2_ZG - r^2_Y | r^2_ZG - r^2_Y_max"
		global affiche 0
	}
	quiet:sum `bonheur'
	// On normalise les indicateurs pour que les p-value s'interpr�tent comme la significativit� de l'�cart de la ZG au bonheur moyen
	quiet:capture gen `bonheur'Normalized = `bonheur' - r(mean)
	quiet:reg `bonheur'Normalized Y
	global r2_Y = e(r2)
	
	// Pour des questions de robustesse, on regarde le r^2 lors de regressions avec des variantes de Y, � savoir diff�rents clusters de Y et ln(Y)
	// Les Y_clus_* ont �t� construit avec "cluster kmeans Y, k(*)" (Y_clus_* = 1 pour les pays les plus pauvres, et cro�t jusqu'� * pour les pays les plus riches)
	// Y_6ile r�partit les pays en 6 groupes homog�nes (pour Y) et de taille �gale
	global r2_Y_max = e(r2)
	foreach Y_clus in Y_clus_4 Y_clus_5 Y_clus_6 Y_clus_7 Y_6ile {
		quiet:reg `bonheur'Normalized i.`Y_clus'
		if e(r2) > $r2_Y_max {
			global r2_Y_max = e(r2)
		}
	}
	quiet:reg `bonheur'Normalized lnY
	if e(r2) > $r2_Y_max {
		global r2_Y_max = e(r2)
	}
	
	quiet:reg `bonheur'Normalized EuropeDelEst MoyenOrient Asie AmeriqueLatine Occident Afrique, nocons
	global r2_ZG = e(r2)
	quiet:reg `bonheur'Normalized Y EuropeDelEst MoyenOrient Asie AmeriqueLatine Occident Afrique, nocons
	quiet:test Y = 0
	display %16,2f $r2_ZG %16,5f r(p) %16,2f $r2_ZG - $r2_Y %16,2f $r2_ZG - $r2_Y_max " :	`bonheur'"
}

/* R�sultats : Zone G�ographique !


           r^2 ZG | p-value du F-test | r^2_ZG - r^2_Y | r^2_ZG - r^2_Y_max
            0,57         0,25722            0,53            0,40 :   tresHeureux
            0,55         0,00981            0,29            0,21 :   heureux
            0,44         0,06269            0,28            0,25 :   tresMalheureux
            0,28         0,12694            0,15            0,10 :   ratioHappy
            0,66         0,00001            0,24            0,20 :   satisfaits6a10
            0,58         0,00025            0,26            0,20 :   satisfaction
            0,53         0,01572            0,39            0,32 :   bonheur
            0,65         0,00006            0,25            0,24 :   bonheurLayard

		   
Quel que soit l'indicateur retenu, la zone g�ographique pr�dit toujours mieux le bonheur d'un pays que son PIB/hab (PPP).
La variance expliqu�e additionnelle est en g�n�ral autour de 30% (+/- 3%), sauf pour l'indicateur tresHeureux, le seul pour lequel le PIB/hab n'est pas significatif au seuil de 20%
Toutefois, pour la plupart des indicateurs, le PIB/hab (PPP) a malgr� tout une valeur pr�dictive, puisque dans 4 cas sur 6, l'hypoth�se nulle du F-test est rejet�e au seuil de 3%
Pour deux estimateurs, on peut m�me affirmer avec une probabilit� inf�rieure � 1/1000 de se tromper qu'il y a une corr�lation entre le PIB/hab et le bonheur du pays, m�me en controlant pour la zone g�ographique.
R�partir les pays en groupes de richesse homog�ne pour tenter de pr�dire leur bonheur n'am�liore jamais drastiquement le r^2 (compar� � une simple r�gression avec Y comme variable d�pendante), comme le montre la derni�re colonne.
L'Europe de l'Est est syst�matiquement significativement moins heureuse. Les autres zones g�ographiques sont souvent significatives pour pr�dire l'indicateur de bonheur :
L'Am�rique latine, l'Occident et l'Asie sont corr�l�s � plus de bonheur, alors que l'Afrique et le Moyen-Orient sont associ�s � moins de bonheur.
*/

/* Test de la significativiit� de la corr�lation entre bien-�tre et revenu au sein de chaque ZG */
global corr = 0
global nb_significatifs_1 = 0
global nb_significatifs_5 = 0
global nb_significatifs_10 = 0
foreach ZG in Afrique AmeriqueLatine MoyenOrient Occident Asie EuropeDelEst {
	if (! $corr) {
		display "corr�lation moyenne | nb significatifs � 1% | nb sign. � 5% | nb sign. � 10% | ZG"
	}
	global corr_$`ZG' = 0 
	global nb_significatifs_1_$`ZG' = 0 
	global nb_significatifs_5_$`ZG' = 0
	global nb_significatifs_10_$`ZG' = 0
	foreach bonheur in tresHeureux heureux tresMalheureux ratioHappy satisfaits6a10 satisfaction bonheur bonheurLayard {
		foreach revenu in Y lnY {
			quiet:reg `bonheur' `revenu' if `ZG'
			quiet:test `revenu'
			if r(p) < 0.01 {
				global nb_significatifs_1_$`ZG' = 1 + $nb_significatifs_1_$`ZG'
			}
			if r(p) < 0.05 {
				global nb_significatifs_5_$`ZG' = 1 + $nb_significatifs_5_$`ZG'
			}
			if r(p) < 0.1 {
				global nb_significatifs_10_$`ZG' = 1 + $nb_significatifs_10_$`ZG'
			}
			quiet: cor `bonheur' `revenu' if `ZG'
			global corr_$`ZG' = $corr_$`ZG' + r(rho)
		}
	}
	global corr = $corr + $corr_$`ZG' / 8
	global nb_significatifs_1 = $nb_significatifs_1_$`ZG' + $nb_significatifs_1
	global nb_significatifs_5 = $nb_significatifs_5_$`ZG' + $nb_significatifs_5
	global nb_significatifs_10 = $nb_significatifs_10_$`ZG' + $nb_significatifs_10 
	display "  " %16,2f $corr_$`ZG' / 8 %16,0f $nb_significatifs_1_$`ZG' %16,0f $nb_significatifs_5_$`ZG' %16,0f $nb_significatifs_10_$`ZG' "             `ZG', (16 r�gressions)"
}
display "  " %16,2f $corr / 8 %16,0f $nb_significatifs_1 %16,0f $nb_significatifs_5 %16,0f $nb_significatifs_10 "             total, (96 r�gressions)"

/* R�sultats :

corr�lation moyenne | nb significatifs � 1% | nb sign. � 5% | nb sign. � 10% | ZG
              0,25               0               0               0             Afrique, (16 r�gressions)
             -0,02               0               0               2             AmeriqueLatine, (16 r�gressions)
              0,75               0               5               7             MoyenOrient, (16 r�gressions)
              0,33               0               0               0             Occident, (16 r�gressions)
              0,47               1               4               6             Asie, (16 r�gressions)
              0,58               6               9              11             EuropeDelEst, (16 r�gressions)

              0,29               7              18              26             total, (96 r�gressions)
*/

/* Qui sont les plus heureux entre l'Am�rique latine et l'Occident ? */
foreach bonheur in tresHeureux heureux tresMalheureux ratioHappy satisfaits6a10 satisfaction bonheur bonheurLayard {
	reg `bonheur' Occident if Occident == 1 | AmeriqueLatine == 1
}
foreach bonheur in tresHeureux heureux tresMalheureux ratioHappy satisfaits6a10 satisfaction bonheur bonheurLayard {
	reg `bonheur' Occident Y if Occident == 1 | AmeriqueLatine == 1
}
/* R�ponse : ils sont autant heureux */
