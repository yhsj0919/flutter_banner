# flutter_banner
flutter循环的banner

```dart

KBanner(
            banners: [
              banner1,
              banner2,
              banner3,
              banner4,
            ],
            itemBuilder: (context, value) {
              return Container(
                child: Image.network(
                  value.toString(),
                  fit: BoxFit.cover,
                ),
              );
            },
          )

```
