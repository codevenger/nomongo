app.config(function($stateProvider, $urlRouterProvider, $locationProvider, $config) {

    $urlRouterProvider.otherwise('/signin');
    
    var main = {
        name: 'main',
        url: '/main',
        templateUrl: 'main.component.html',
        controller: 'mainCtrl'
    }
    
    $stateProvider.state(main);

    $stateProvider
    
        .state('signin', {
            url: '/signin',
            templateUrl : 'signin/signin.component.html',
            controller : 'signinCtrl'
        })

        .state('home', {
            parent: main,
            url: '/home',
            templateUrl : 'home/home.component.html',
            controller : 'homeCtrl'
        })

        .state('signout', {
            url: '/signout',
            templateUrl : 'signin/signin.component.html',
            controller : 'signoutCtrl'
        })
        
        .state('groups', {
            parent: main,
            url: '/groups',
            templateUrl: '/groups'
        })
        
        .state('users', {
            parent: main,
            url: '/users',
            templateUrl: '/users'
        });
        
    
});
