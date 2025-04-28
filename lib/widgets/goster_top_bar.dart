import 'package:flutter/material.dart';
import 'package:fluttergoster/pages/browse_page.dart';
import 'package:fluttergoster/pages/home_page.dart';
import 'package:fluttergoster/pages/me_page.dart'; // Add this import
import 'package:fluttergoster/services/api_service.dart';
import 'package:fluttergoster/widgets/search_modal.dart';

class GosterTopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final String? title;

  const GosterTopBar({
    super.key,
    this.showBackButton = false,
    this.onBackPressed,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenir la largeur de l'écran pour des calculs responsives
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculer dynamiquement la taille des icônes et l'espacement
    final iconSize = _calculateIconSize(screenWidth);
    final horizontalPadding = _calculateHorizontalPadding(screenWidth);
    final iconSpacing = _calculateIconSpacing(screenWidth);

    // Hauteur de la barre dynamique
    final barHeight = _calculateBarHeight(screenWidth);

    return Container(
      color: Colors.black,
      height: barHeight,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Section gauche - Bouton retour ou logo
              if (showBackButton)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: iconSize,
                  ),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  padding: EdgeInsets.all(iconSpacing / 3),
                )
              else
                SizedBox(
                  width: iconSize + iconSpacing,
                ), // Espace pour aligner les éléments
              // Section centrale - Icônes de navigation
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNavItem(
                      context,
                      Icons.explore,
                      0,
                      iconSize,
                      iconSpacing,
                    ),
                    _buildNavItem(
                      context,
                      Icons.movie,
                      1,
                      iconSize,
                      iconSpacing,
                    ),
                    _buildNavItem(context, Icons.tv, 2, iconSize, iconSpacing),
                  ],
                ),
              ),

              // Section droite - Recherche et profil
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: Colors.white,
                      size: iconSize,
                    ),
                    onPressed: () {
                      SearchModal.show(context);
                    },
                    padding: EdgeInsets.all(iconSpacing / 3),
                  ),
                  SizedBox(width: iconSpacing / 2),
                  IconButton(
                    icon: Icon(
                      Icons.account_circle,
                      color: Colors.white,
                      size: iconSize,
                    ),
                    onPressed: () {
                      // Navigate to the Me page
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => const MePage()));
                    },
                    padding: EdgeInsets.all(iconSpacing / 3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    int index,
    double iconSize,
    double spacing,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: iconSize),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () {
          // Navigation vers la section correspondante
          if (index == 0) {
            // Navigation vers la page d'accueil (Home)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BrowsePage(mediaType: 'movie')),
            );
          } else if (index == 2) {
            // Navigation vers la page des séries TV
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BrowsePage(mediaType: 'tv')),
            );
          } else if (index == 3) {
            // Navigation vers d'autres fonctionnalités (Cast)
            // À implémenter selon besoin
          }
        },
      ),
    );
  }

  // Calcule dynamiquement la taille de l'icône en fonction de la largeur de l'écran
  double _calculateIconSize(double screenWidth) {
    if (screenWidth > 1200) {
      return 28.0; // Grand écran
    } else if (screenWidth > 800) {
      return 24.0; // Écran moyen
    } else if (screenWidth > 600) {
      return 22.0; // Petit écran
    } else {
      return 20.0; // Très petit écran (mobile)
    }
  }

  // Calcule dynamiquement le padding horizontal en fonction de la largeur de l'écran
  double _calculateHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) {
      return 24.0; // Grand écran
    } else if (screenWidth > 800) {
      return 20.0; // Écran moyen
    } else if (screenWidth > 600) {
      return 16.0; // Petit écran
    } else {
      return 12.0; // Très petit écran (mobile)
    }
  }

  // Calcule dynamiquement l'espacement entre les icônes
  double _calculateIconSpacing(double screenWidth) {
    if (screenWidth > 1200) {
      return 20.0; // Grand écran
    } else if (screenWidth > 800) {
      return 16.0; // Écran moyen
    } else if (screenWidth > 600) {
      return 12.0; // Petit écran
    } else {
      return 8.0; // Très petit écran (mobile)
    }
  }

  // Calcule dynamiquement la hauteur de la barre
  double _calculateBarHeight(double screenWidth) {
    if (screenWidth > 800) {
      return 64.0; // Grand écran
    } else {
      return 56.0; // Petit écran
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(64.0); // Hauteur maximale
}
