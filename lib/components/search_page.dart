// ----SearchPage--------------------------------------------------------------------------

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}


class _SearchPageState extends State<SearchPage> {
  final fromKey = GlobalKey<FormState>();
  final PageController _pageControlSearch = PageController(initialPage: 0);

  int actionPageSearch = 0;

  void _goToPageSearch(int pageIndexSearch) {
    _pageControlSearch.animateToPage(
      pageIndexSearch,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Container(
              color: Theme.of(context).snackBarTheme.backgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {
                      _goToPageSearch(0);
                      setState(() {
                        actionPageSearch = 0;
                      });
                    },
                    child: actionPageSearch == 0
                        ? Text(
                            languageProvider.translate(
                                en: "FEMALE", th: "ตัวเมีย"),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .snackBarTheme
                                  .contentTextStyle
                                  ?.color,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1, // ความหนาของเส้นใต้
                              decorationColor: Theme.of(context)
                                  .snackBarTheme
                                  .contentTextStyle
                                  ?.color,
                              fontSize: 18,
                              height: 3,
                            ),
                          )
                        : Text(
                            languageProvider.translate(
                                en: "FEMALE", th: "ตัวเมีย"),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              height: 3,
                            )),
                  ),
                  GestureDetector(
                    onTap: () {
                      _goToPageSearch(1);
                      setState(() {
                        actionPageSearch = 1;
                      });
                    },
                    child: actionPageSearch == 1
                        ? Text(
                            languageProvider.translate(
                                en: "MALE", th: "ตัวผู้"),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .snackBarTheme
                                  .contentTextStyle
                                  ?.color,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1, // ความหนาของเส้นใต้
                              decorationColor: Theme.of(context)
                                  .snackBarTheme
                                  .contentTextStyle
                                  ?.color, // สีของเส้นใต้
                              fontSize: 18,
                              height: 3,
                            ),
                          )
                        : Text(
                            languageProvider.translate(
                                en: "MALE", th: "ตัวผู้"),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              height: 3,
                            )),
                  ),
                  GestureDetector(
                    onTap: () {
                      _goToPageSearch(2);
                      setState(() {
                        actionPageSearch = 2;
                      });
                    },
                    child: actionPageSearch == 2
                        ? Text(
                            languageProvider.translate(
                                en: "KITTEN", th: "ลูกแมว"),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .snackBarTheme
                                  .contentTextStyle
                                  ?.color,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1, // ความหนาของเส้นใต้
                              decorationColor: Theme.of(context)
                                  .snackBarTheme
                                  .contentTextStyle
                                  ?.color, // สีของเส้นใต้
                              fontSize: 18,
                              height: 3,
                            ),
                          )
                        : Text(
                            languageProvider.translate(
                                en: "KITTEN", th: "ลูกแมว"),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              height: 3,
                            )),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
            height: 20,
          ),
          Expanded(
              child: PageView(
            controller: _pageControlSearch,
            scrollDirection: Axis.horizontal,
            onPageChanged: (indexS) {
              setState(() {
                actionPageSearch = indexS;
              });
            },
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    //Section 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Female 1
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740288948/F1-removebg-preview_b0vnu5.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Princess Paws',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Female 2
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740288947/F2-removebg-preview_upsxlj.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Floral Feline',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Female 3
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740288946/F3-removebg-preview_nl7eks.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Elegant Diva',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Female 4
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289084/F4-removebg-preview_ncl6mt.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Pastel Kitty',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Female 5
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289084/F5-removebg-preview_mynzc3.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Royal Queen',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Female 6
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289084/F6-removebg-preview_p0x3j4.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Fairy Tale Cat',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 4
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Female 7
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289083/F7-removebg-preview_hrobn2.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Sweet Lolita',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Female 8
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289083/F8-removebg-preview_yipil7.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Chic & Trendy',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Female 9
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289082/F9-removebg-preview_glqkuw.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Romantic Lace',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Female 10
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289082/F10-removebg-preview_ka2hjm.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Tutu & Frills',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    //Section 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Male 1
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290117/M1-removebg-preview_dy7jvt.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Gentleman Paws',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Male 2
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M2-removebg-preview_fhbtuj.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Sporty Cat',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Male 3
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M3-removebg-preview_w7onjr.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Cool Street Style',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Male 4
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M4-removebg-preview_eu2eum.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Dapper Kitty',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Male 5
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M5-removebg-preview_ptzi7o.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Retro Vibes',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Male 6
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M6-removebg-preview_wwab4z.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Rockstar Meow',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 4
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Male 7
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M7-removebg-preview_kq2mpl.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Minimalist Chic',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Male 8
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M8-removebg-preview_i94h7h.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Bad Boy Cat',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 9
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Male 9
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/M9-removebg-preview_yulrpr.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Sailor & Navy',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Male 10
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/M10-removebg-preview_zrc7cm.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Adventure Outfit',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    //Section 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Kittin 1
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/K1-removebg-preview_sha0wo.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Baby Meow',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Kittin 2
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/K2-removebg-preview_ijiu0l.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Fluffy Bunny',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Kittin 3
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/K3-removebg-preview_p8ysrz.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Candy Cutie',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Kittin 4
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/K4-removebg-preview_mxeobw.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Little Sailor',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Kittin 5
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290114/K5-removebg-preview_h7u4gt.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Tiny Teddy',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Kittin 6
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290114/K6-removebg-preview_u4upj9.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Playful Paws',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 4
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Kittin 7
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290114/K7-removebg-preview_ynkt7n.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Rainbow Kitten',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Kittin 8
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290114/K8-removebg-preview_mxeqvn.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Mini Prince & Princess',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 9
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Kittin 9
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290114/K9-removebg-preview_nbydc8.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Dreamy Cloud',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Kittin 10
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290114/K10-removebg-preview_xmzj5i.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Cozy Pajamas',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          )) // ส่วนขยาย ภายใน
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        padding: EdgeInsets.all(5),
        child: Form(
            key: fromKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    labelText: languageProvider.translate(
                        en: 'Search for products', th: 'ค้นหาสินค้า'),
                    prefixIcon: Icon(Icons.search),
                  ),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ],
            )),
      ),
    );
  }
}
