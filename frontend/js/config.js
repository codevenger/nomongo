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
            templateUrl: 'default/default.component.html',
            controller: 'defaultCtrl',
            controllerAs: 'tctrl',
            render: {
                name: 'Tipos Usuários',
                resource: 'groups',
                columns: [
                    {
                        title: "Código",
                        field: "id"
                    },
                    {
                        title: "Descrição",
                        field: "descrp"
                    }               
                ]
            }
        })
        
        .state('users', {
            parent: main,
            url: '/users',
            templateUrl: 'default/default.component.html',
            controller: 'defaultCtrl',
            controllerAs: 'tctrl',
            render: {
                name: 'Usuários',
                resource: 'users',
                columns: [
                    {
                        title: "Código",
                        field: "id"
                    },
                    {
                        title: "Usuário",
                        field: "username"
                    },               
                    {
                        title: "Nome",
                        field: "name"
                    },
                    {
                        title: "Idioma",
                        field: "language"
                    }
                ]
            }
        });
        
    
});
