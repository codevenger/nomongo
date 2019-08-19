var app = angular.module('NoMongo', ['main', 'ui.router', 'ngSanitize', 'ngMaterial', 'ngMessages']);

app.constant('$config', {
    url: 'http://142.93.75.2',
    pagination: 'server'
});


app.config(function($stateProvider, $urlRouterProvider, $locationProvider) {

    $urlRouterProvider.otherwise('signin');

    $stateProvider
    
        .state('signin', {
            url: '/signin',
            templateUrl : 'signin/signin.component.html',
            controller : 'signinCtrl'
        })

        .state('home', {
            url: '/home',
            templateUrl : 'home/home.component.html',
            controller : 'homeCtrl'
        })

        .state('signout', {
            url: '/signout',
            templateUrl : 'signout/signout.component.html',
            controller : 'signoutCtrl'
        });
        
        $locationProvider.html5Mode(true);
    
});


angular.module("main",[]);


app.controller("signinCtrl", function($sce, $scope, $state, $http, $config, $mdToast){
    $scope.submit = function() {
        if(! $scope.username) {
            alert("Você não informou um usuário");
            return false;
        }
        if(! $scope.password) {
            alert("Você não informou uma senha");
            return false;
        }
        
        var send = {
            username: $scope.username,
            password: $scope.password
        };
        
        $http.post($config.url+'/sys/signin', send)
            .then(function(response) {
                console.log('Sucesso: ', response);
                $mdToast.show(
                    $mdToast.simple()
                    .position('top right')
                    .textContent('Bem vindo, '+response.data.user.name)
                    .theme('success-toast')
                    .hideDelay(2000));
                $state.go('home', { reload: true});
            }, function errorCallback(response) {
                if(response.data) {
                    response = response.data;
                }
                var decoded = angular.element('<textarea />').html(response.message).text();
                $mdToast.show(
                    $mdToast.simple()
                    .position('top right')
                    .textContent($sce.trustAsHtml(decoded))
                    .theme('error-toast')
                    .hideDelay(2000));
                console.log('Erro: ', response);
            });
    }
    
});

app.controller("homeCtrl", function($scope, $state){

});


angular.module("main").controller("mainController",function($scope){
    var data = "roger";
    $scope.data = "that";
});
 
