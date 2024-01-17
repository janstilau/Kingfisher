
import UIKit
import Kingfisher

class GIFHeavyViewController: UIViewController {
    let stackView = UIStackView()
    let imageView_1 = AnimatedImageView()
    let imageView_2 = AnimatedImageView()
    let imageView_3 = AnimatedImageView()
    let imageView_4 = AnimatedImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                stackView.topAnchor.constraint(equalTo: view.topAnchor),
                stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
        
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        
        stackView.addArrangedSubview(imageView_1)
        stackView.addArrangedSubview(imageView_2)
        stackView.addArrangedSubview(imageView_3)
        stackView.addArrangedSubview(imageView_4)
        
        imageView_1.contentMode = .scaleAspectFit
        imageView_2.contentMode = .scaleAspectFit
        imageView_3.contentMode = .scaleAspectFit
        imageView_4.contentMode = .scaleAspectFit
        
        let url = URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/GIF/GifHeavy.gif")

        imageView_1.kf.setImage(with: url)
        imageView_2.kf.setImage(with: url)
        imageView_3.kf.setImage(with: url)
        imageView_4.kf.setImage(with: url)
    }
}
